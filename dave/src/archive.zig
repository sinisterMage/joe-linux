//! Reading and writing `.dave` package files.
//!
//! A package is a zstd-compressed tar stream whose first member is
//! `manifest.zon`, followed by one `files/<path>` member per regular file.
//! Everything else about the package tree comes from the manifest.
//!
//! Reading is pure Zig. Writing pipes through the `zstd` program, because the
//! standard library can only decompress; the level is capped so the stream
//! stays within the decoder's 8 MiB window.

const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const zstd = std.compress.zstd;
const Sha256 = std.crypto.hash.sha2.Sha256;
const manifest_mod = @import("manifest.zig");
const Manifest = manifest_mod.Manifest;
const seal = @import("seal.zig");

pub const manifest_member = "manifest.zon";
pub const payload_prefix = "files/";
pub const max_manifest_bytes = 64 * 1024 * 1024;

pub const Digest = [Sha256.digest_length * 2]u8;

pub fn hex(digest: [Sha256.digest_length]u8) Digest {
    return std.fmt.bytesToHex(digest, .lower);
}

pub fn hashBytes(bytes: []const u8) Digest {
    var out: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(bytes, &out, .{});
    return hex(out);
}

pub fn hashFile(io: Io, dir: Io.Dir, sub_path: []const u8) !Digest {
    var file = try dir.openFile(io, sub_path, .{});
    defer file.close(io);
    var buf: [64 * 1024]u8 = undefined;
    var reader = file.reader(io, &buf);
    var hasher: Sha256 = .init(.{});
    var chunk: [64 * 1024]u8 = undefined;
    while (true) {
        const n = try reader.interface.readSliceShort(&chunk);
        if (n == 0) break;
        hasher.update(chunk[0..n]);
    }
    var out: [Sha256.digest_length]u8 = undefined;
    hasher.final(&out);
    return hex(out);
}

/// A writer that hashes and counts whatever passes through it.
pub const HashingSink = struct {
    out: ?*Io.Writer,
    hasher: Sha256 = .init(.{}),
    count: u64 = 0,
    writer: Io.Writer,

    pub fn init(out: ?*Io.Writer, buffer: []u8) HashingSink {
        return .{ .out = out, .writer = .{ .buffer = buffer, .vtable = &.{ .drain = drain } } };
    }

    fn consume(self: *HashingSink, bytes: []const u8) Io.Writer.Error!void {
        if (bytes.len == 0) return;
        self.hasher.update(bytes);
        self.count += bytes.len;
        if (self.out) |o| try o.writeAll(bytes);
    }

    fn drain(w: *Io.Writer, data: []const []const u8, splat: usize) Io.Writer.Error!usize {
        const self: *HashingSink = @alignCast(@fieldParentPtr("writer", w));
        try self.consume(w.buffered());
        w.end = 0;
        var n: usize = 0;
        for (data[0 .. data.len - 1]) |part| {
            try self.consume(part);
            n += part.len;
        }
        const last = data[data.len - 1];
        for (0..splat) |_| {
            try self.consume(last);
            n += last.len;
        }
        return n;
    }

    pub fn finish(self: *HashingSink) Io.Writer.Error!Digest {
        try self.writer.flush();
        var out: [Sha256.digest_length]u8 = undefined;
        self.hasher.final(&out);
        return hex(out);
    }
};

// ---------------------------------------------------------------------------
// Writing
// ---------------------------------------------------------------------------

pub const PackOptions = struct {
    /// Package metadata. `files` is ignored and rebuilt from the tree.
    meta: Manifest,
    /// The staged tree, opened for iteration.
    src: Io.Dir,
    out_dir: Io.Dir,
    zstd_level: u8 = 19,
    /// When set, every regular file that is not configuration gets a seal:
    /// its fs-verity digest and the package's declared operations for it,
    /// signed with this key.
    code_key: ?seal.SigningKey = null,
};

const Staged = struct {
    file: manifest_mod.File,
    inode: Io.File.INode,
};

/// Packs a staged tree into `out_dir` and returns the package file name.
pub fn pack(arena: Allocator, io: Io, options: PackOptions) ![]const u8 {
    std.debug.assert(options.zstd_level <= 19);
    var staged: std.ArrayList(Staged) = .empty;
    {
        var walker = try options.src.walk(arena);
        defer walker.deinit();
        while (try walker.next(io)) |entry| {
            const path = try arena.dupe(u8, entry.path);
            if (!manifest_mod.validPath(path)) return error.InvalidPath;
            const st = try options.src.statFile(io, path, .{ .follow_symlinks = false });
            var f: manifest_mod.File = .{ .path = path, .mode = st.permissions.toMode() & 0o7777 };
            switch (st.kind) {
                .directory => f.kind = .dir,
                .sym_link => {
                    var buf: [4096]u8 = undefined;
                    const n = try options.src.readLink(io, path, &buf);
                    f.kind = .symlink;
                    f.mode = 0o777;
                    f.target = try arena.dupe(u8, buf[0..n]);
                },
                .file => {
                    f.kind = .file;
                    f.size = st.size;
                    f.config = std.mem.startsWith(u8, path, "etc/");
                },
                else => return error.UnsupportedFileType,
            }
            try staged.append(arena, .{ .file = f, .inode = st.inode });
        }
    }
    std.mem.sort(Staged, staged.items, {}, struct {
        fn lessThan(_: void, a: Staged, b: Staged) bool {
            return std.mem.order(u8, a.file.path, b.file.path) == .lt;
        }
    }.lessThan);

    // The first path seen for an inode keeps the contents; later ones link to it.
    var first_by_inode: std.AutoHashMapUnmanaged(Io.File.INode, []const u8) = .empty;
    for (staged.items) |*s| {
        if (s.file.kind != .file) continue;
        const gop = try first_by_inode.getOrPut(arena, s.inode);
        if (gop.found_existing) {
            s.file.kind = .hardlink;
            s.file.target = gop.value_ptr.*;
            s.file.size = 0;
            s.file.config = false;
        } else {
            gop.value_ptr.* = s.file.path;
            const digest = try hashFile(io, options.src, s.file.path);
            s.file.sha256 = try arena.dupe(u8, &digest);
            if (options.code_key) |key| {
                // Configuration stays editable, so it cannot be sealed.
                if (!s.file.config) {
                    const verity = try seal.verityDigestOfFile(io, options.src, s.file.path);
                    const ops = try seal.operationsText(arena, options.meta.operations, s.file.path);
                    const signature = try key.sign(arena, verity, ops);
                    s.file.verity = try arena.dupe(u8, &std.fmt.bytesToHex(verity, .lower));
                    s.file.seal = try arena.dupe(u8, &std.fmt.bytesToHex(signature, .lower));
                }
            }
        }
    }

    var manifest = options.meta;
    const files = try arena.alloc(manifest_mod.File, staged.items.len);
    for (staged.items, files) |s, *f| f.* = s.file;
    manifest.files = files;
    manifest.format = manifest_mod.current_format;

    var manifest_text: Io.Writer.Allocating = .init(arena);
    try manifest.write(&manifest_text.writer);

    const name = try manifest.fileName(arena);
    const tmp_name = try std.fmt.allocPrint(arena, ".{s}.partial", .{name});
    {
        var out_file = try options.out_dir.createFile(io, tmp_name, .{});
        defer out_file.close(io);
        errdefer options.out_dir.deleteFile(io, tmp_name) catch {};

        const level = try std.fmt.allocPrint(arena, "-{d}", .{options.zstd_level});
        var child = try std.process.spawn(io, .{
            .argv = &.{ "zstd", "-q", "-T0", level, "-c" },
            .stdin = .pipe,
            .stdout = .{ .file = out_file },
        });
        errdefer child.kill(io);

        var pipe_buf: [64 * 1024]u8 = undefined;
        var pipe = child.stdin.?.writer(io, &pipe_buf);
        var tar: std.tar.Writer = .{ .underlying_writer = &pipe.interface };
        try tar.writeFileBytes(manifest_member, manifest_text.written(), .{ .mode = 0o644 });
        for (files) |f| {
            if (f.kind != .file) continue;
            var src_file = try options.src.openFile(io, f.path, .{});
            defer src_file.close(io);
            var read_buf: [64 * 1024]u8 = undefined;
            var reader = src_file.reader(io, &read_buf);
            const member = try std.fmt.allocPrint(arena, payload_prefix ++ "{s}", .{f.path});
            try tar.writeFileStream(member, f.size, &reader.interface, .{ .mode = 0o644 });
        }
        try tar.finishPedantically();
        try pipe.interface.flush();
        child.stdin.?.close(io);
        child.stdin = null;

        const term = try child.wait(io);
        if (!term.success()) return error.CompressionFailed;
        try out_file.sync(io);
    }
    try options.out_dir.rename(tmp_name, options.out_dir, name, io);
    return name;
}

// ---------------------------------------------------------------------------
// Reading
// ---------------------------------------------------------------------------

pub const PackageReader = struct {
    io: Io,
    file: Io.File,
    file_buf: [64 * 1024]u8,
    file_reader: Io.File.Reader,
    window: []u8,
    decompress: zstd.Decompress,
    name_buf: [4096]u8,
    link_buf: [4096]u8,
    iter: std.tar.Iterator,
    current: ?std.tar.Iterator.File,

    pub const Entry = struct {
        /// Path relative to the root, as in the manifest.
        path: []const u8,
        size: u64,
    };

    pub fn open(gpa: Allocator, io: Io, dir: Io.Dir, sub_path: []const u8) !*PackageReader {
        const self = try gpa.create(PackageReader);
        errdefer gpa.destroy(self);
        self.io = io;
        self.file = try dir.openFile(io, sub_path, .{});
        errdefer self.file.close(io);
        self.window = try gpa.alloc(u8, zstd.default_window_len + zstd.block_size_max);
        self.file_reader = self.file.reader(io, &self.file_buf);
        self.decompress = .init(&self.file_reader.interface, self.window, .{});
        self.iter = .init(&self.decompress.reader, .{
            .file_name_buffer = &self.name_buf,
            .link_name_buffer = &self.link_buf,
        });
        self.current = null;
        return self;
    }

    pub fn close(self: *PackageReader, gpa: Allocator) void {
        self.file.close(self.io);
        gpa.free(self.window);
        gpa.destroy(self);
    }

    /// Reads the manifest. Must be the first call after `open`.
    pub fn readManifest(self: *PackageReader, arena: Allocator) !Manifest {
        const member = (try self.iter.next()) orelse return error.InvalidPackage;
        if (member.kind != .file or !std.mem.eql(u8, member.name, manifest_member)) return error.InvalidPackage;
        if (member.size > max_manifest_bytes) return error.InvalidPackage;
        var text: Io.Writer.Allocating = .init(arena);
        try self.iter.streamRemaining(member, &text.writer);
        return Manifest.parse(arena, text.written());
    }

    /// The next regular file in the payload, or null at the end.
    pub fn next(self: *PackageReader) !?Entry {
        const member = (try self.iter.next()) orelse return null;
        if (member.kind != .file) return error.InvalidPackage;
        if (!std.mem.startsWith(u8, member.name, payload_prefix)) return error.InvalidPackage;
        const path = member.name[payload_prefix.len..];
        if (!manifest_mod.validPath(path)) return error.InvalidPackage;
        self.current = member;
        return .{ .path = path, .size = member.size };
    }

    /// Writes the contents of the entry last returned by `next`.
    pub fn stream(self: *PackageReader, w: *Io.Writer) !void {
        try self.iter.streamRemaining(self.current.?, w);
        self.current = null;
    }
};

/// Reads only the manifest of a package file.
pub fn readManifestOf(gpa: Allocator, arena: Allocator, io: Io, dir: Io.Dir, sub_path: []const u8) !Manifest {
    const reader = try PackageReader.open(gpa, io, dir, sub_path);
    defer reader.close(gpa);
    return reader.readManifest(arena);
}

const testing = std.testing;

test "pack and read back" {
    const io = testing.io;
    var arena_state: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var tmp = testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();

    try tmp.dir.createDirPath(io, "stage/usr/bin");
    try tmp.dir.createDirPath(io, "stage/etc");
    var stage = try tmp.dir.openDir(io, "stage", .{ .iterate = true });
    defer stage.close(io);
    try stage.writeFile(io, .{ .sub_path = "usr/bin/hello", .data = "#!/bin/sh\necho hello\n" });
    try stage.setFilePermissions(io, "usr/bin/hello", .fromMode(0o755), .{});
    try stage.writeFile(io, .{ .sub_path = "etc/hello.conf", .data = "greeting=hello\n" });
    try stage.symLink(io, "hello", "usr/bin/hi", .{});
    try stage.hardLink("usr/bin/hello", stage, "usr/bin/hello-again", io, .{});
    const big = try arena.alloc(u8, 3 * 1024 * 1024);
    for (big, 0..) |*b, i| b.* = @truncate(i *% 2654435761 >> 7);
    try stage.writeFile(io, .{ .sub_path = "usr/bin/big", .data = big });

    const name = try pack(arena, io, .{
        .meta = .{ .name = "hello", .version = "1.0-r1", .depends = &.{"glibc"} },
        .src = stage,
        .out_dir = tmp.dir,
    });
    try testing.expectEqualStrings("hello-1.0-r1-x86_64.dave", name);

    const reader = try PackageReader.open(testing.allocator, io, tmp.dir, name);
    defer reader.close(testing.allocator);
    const m = try reader.readManifest(arena);
    try testing.expectEqualStrings("hello", m.name);
    try testing.expectEqualStrings("glibc", m.depends[0]);

    var kinds: std.StringHashMapUnmanaged(manifest_mod.File) = .empty;
    for (m.files) |f| try kinds.put(arena, f.path, f);
    try testing.expectEqual(manifest_mod.FileKind.dir, kinds.get("usr/bin").?.kind);
    try testing.expectEqual(manifest_mod.FileKind.symlink, kinds.get("usr/bin/hi").?.kind);
    try testing.expectEqualStrings("hello", kinds.get("usr/bin/hi").?.target.?);
    try testing.expectEqual(@as(u32, 0o755), kinds.get("usr/bin/hello").?.mode);
    try testing.expect(kinds.get("etc/hello.conf").?.config);
    // Exactly one of the two hard-linked names carries the contents.
    const a = kinds.get("usr/bin/hello").?;
    const b = kinds.get("usr/bin/hello-again").?;
    try testing.expect((a.kind == .file) != (b.kind == .file));
    try testing.expect((a.kind == .hardlink) != (b.kind == .hardlink));

    var seen: usize = 0;
    while (try reader.next()) |entry| {
        var sink_buf: [4096]u8 = undefined;
        var sink: HashingSink = .init(null, &sink_buf);
        try reader.stream(&sink.writer);
        const digest = try sink.finish();
        try testing.expectEqualStrings(kinds.get(entry.path).?.sha256.?, &digest);
        try testing.expectEqual(entry.size, sink.count);
        if (std.mem.eql(u8, entry.path, "usr/bin/big")) try testing.expectEqualStrings(&hashBytes(big), &digest);
        seen += 1;
    }
    try testing.expectEqual(@as(usize, 3), seen);
}

test "rejects files that are not packages" {
    const io = testing.io;
    var arena_state: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena_state.deinit();
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "junk.dave", .data = "this is not a package" });
    try testing.expect(std.meta.isError(readManifestOf(testing.allocator, arena_state.allocator(), io, tmp.dir, "junk.dave")));
}
