//! Boot entries on the EFI system partition.
//!
//! One Boot Loader Specification type 1 entry exists per deployment:
//! `loader/entries/joe-<id>.conf`. Every entry has `sort-key joe`, so
//! systemd-boot orders them by `version` alone, and `version` is not a release
//! number but a *priority*: a counter that is bumped each time a deployment is
//! chosen. Activating an upgrade and rolling back are therefore the same act
//! (give the target the highest priority), a rollback is persistent, and the
//! fallback after a failed boot is whatever was chosen before.
//!
//! The boot loader also owns the health state. A new deployment is written as
//! `joe-<id>+3.conf`; systemd-boot counts the suffix down on each attempt
//! (`+2-1`, `+1-2`, `+0-3`) and systemd-bless-boot removes it once the boot
//! check has passed. dave reads the state from the file name and never keeps
//! a second copy that could drift.
//!
//! All of this was verified against systemd-boot 262 in tests/vm/boot_contract.py.

const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const archive = @import("archive.zig");
const db = @import("db.zig");

pub const entries_dir = "loader/entries";
pub const kernels_dir = "joe/kernels";
pub const default_tries = 3;
const prefix = "joe-";
const suffix = ".conf";

pub const Health = enum {
    /// Booted successfully at least once.
    good,
    /// Not yet proven; boot attempts remain.
    trial,
    /// Ran out of attempts without passing its boot check.
    bad,
};

pub const Entry = struct {
    id: u32,
    priority: u64,
    tries_left: ?u32 = null,
    tries_done: u32 = 0,
    /// Path of the kernel image, relative to the ESP root with a leading slash.
    kernel: []const u8,
    options: []const u8,
    file_name: []const u8 = "",

    pub fn health(e: Entry) Health {
        const left = e.tries_left orelse return .good;
        return if (left == 0) .bad else .trial;
    }
};

const ParsedName = struct { id: u32, tries_left: ?u32, tries_done: u32 };

/// Parses `joe-<id>[+<left>[-<done>]].conf`.
fn parseName(name: []const u8) ?ParsedName {
    if (!std.mem.startsWith(u8, name, prefix) or !std.mem.endsWith(u8, name, suffix)) return null;
    const stem = name[prefix.len .. name.len - suffix.len];
    const plus = std.mem.indexOfScalar(u8, stem, '+') orelse
        return .{ .id = std.fmt.parseInt(u32, stem, 10) catch return null, .tries_left = null, .tries_done = 0 };
    const id = std.fmt.parseInt(u32, stem[0..plus], 10) catch return null;
    const counters = stem[plus + 1 ..];
    const dash = std.mem.indexOfScalar(u8, counters, '-');
    const left = std.fmt.parseInt(u32, counters[0 .. dash orelse counters.len], 10) catch return null;
    const done = if (dash) |d| std.fmt.parseInt(u32, counters[d + 1 ..], 10) catch return null else 0;
    return .{ .id = id, .tries_left = left, .tries_done = done };
}

fn field(text: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.tokenizeScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (!std.mem.startsWith(u8, line, key)) continue;
        if (line.len == key.len) return "";
        if (line[key.len] != ' ' and line[key.len] != '\t') continue;
        return std.mem.trim(u8, line[key.len..], " \t");
    }
    return null;
}

/// Every deployment entry on the ESP, in the order systemd-boot would try
/// them: usable entries by descending priority, then exhausted ones.
pub fn list(arena: Allocator, io: Io, esp: Io.Dir) ![]Entry {
    var out: std.ArrayList(Entry) = .empty;
    var dir = esp.openDir(io, entries_dir, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return out.items,
        else => return err,
    };
    defer dir.close(io);
    var it = dir.iterate();
    while (try it.next(io)) |e| {
        const parsed = parseName(e.name) orelse continue;
        const text = dir.readFileAlloc(io, e.name, arena, .limited(64 * 1024)) catch continue;
        const priority = std.fmt.parseInt(u64, field(text, "version") orelse continue, 10) catch continue;
        try out.append(arena, .{
            .id = parsed.id,
            .priority = priority,
            .tries_left = parsed.tries_left,
            .tries_done = parsed.tries_done,
            .kernel = field(text, "linux") orelse continue,
            .options = field(text, "options") orelse "",
            .file_name = try arena.dupe(u8, e.name),
        });
    }
    std.mem.sort(Entry, out.items, {}, bootOrder);
    return out.items;
}

fn bootOrder(_: void, a: Entry, b: Entry) bool {
    const a_bad = a.health() == .bad;
    const b_bad = b.health() == .bad;
    if (a_bad != b_bad) return b_bad;
    if (a.priority != b.priority) return a.priority > b.priority;
    return a.id > b.id;
}

pub fn find(entries: []const Entry, id: u32) ?Entry {
    for (entries) |e| if (e.id == id) return e;
    return null;
}

/// The entry systemd-boot will start next, if any is usable.
pub fn defaultEntry(entries: []const Entry) ?Entry {
    if (entries.len == 0 or entries[0].health() == .bad) return null;
    return entries[0];
}

pub fn highestPriority(entries: []const Entry) u64 {
    var max: u64 = 0;
    for (entries) |e| max = @max(max, e.priority);
    return max;
}

pub const WriteOptions = struct {
    id: u32,
    priority: u64,
    kernel: []const u8,
    options: []const u8,
    /// True for a deployment that has never booted: it gets boot counting.
    counted: bool,
};

/// Writes the entry for a deployment, replacing any existing entry for it.
/// The file appears under its final name only once complete.
pub fn write(arena: Allocator, io: Io, esp: Io.Dir, options: WriteOptions) !void {
    try esp.createDirPath(io, entries_dir);
    var dir = try esp.openDir(io, entries_dir, .{ .iterate = true });
    defer dir.close(io);

    const name = if (options.counted)
        try std.fmt.allocPrint(arena, prefix ++ "{d}+{d}" ++ suffix, .{ options.id, default_tries })
    else
        try std.fmt.allocPrint(arena, prefix ++ "{d}" ++ suffix, .{options.id});
    const text = try std.fmt.allocPrint(arena,
        \\title joe Linux (deployment {d})
        \\sort-key joe
        \\version {d}
        \\linux {s}
        \\options {s}
        \\
    , .{ options.id, options.priority, options.kernel, options.options });

    // Remove stale names for this deployment first; if we are interrupted in
    // between, the deployment merely has no entry, which is always safe.
    try removeFrom(arena, io, dir, options.id);
    // The temporary name does not end in ".conf", so the loader ignores it.
    const tmp = try std.fmt.allocPrint(arena, ".{s}.tmp", .{name});
    try dir.writeFile(io, .{ .sub_path = tmp, .data = text });
    {
        var f = try dir.openFile(io, tmp, .{});
        defer f.close(io);
        f.sync(io) catch {};
    }
    try dir.rename(tmp, dir, name, io);
}

/// Removes every entry file belonging to a deployment.
pub fn remove(arena: Allocator, io: Io, esp: Io.Dir, id: u32) !void {
    var dir = esp.openDir(io, entries_dir, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer dir.close(io);
    try removeFrom(arena, io, dir, id);
}

fn removeFrom(arena: Allocator, io: Io, dir: Io.Dir, id: u32) !void {
    var doomed: std.ArrayList([]const u8) = .empty;
    var it = dir.iterate();
    while (try it.next(io)) |e| {
        const parsed = parseName(e.name) orelse continue;
        if (parsed.id == id) try doomed.append(arena, try arena.dupe(u8, e.name));
    }
    for (doomed.items) |name| try dir.deleteFile(io, name);
}

/// Copies a kernel image to the ESP under a name derived from its contents and
/// returns its loader path. An image already present is not rewritten, so an
/// existing entry can never end up pointing at different bytes.
pub fn installKernel(arena: Allocator, io: Io, esp: Io.Dir, src_dir: Io.Dir, src_path: []const u8) ![]const u8 {
    const digest = try archive.hashFile(io, src_dir, src_path);
    const rel = try std.fmt.allocPrint(arena, kernels_dir ++ "/{s}.efi", .{digest[0..16]});
    const loader_path = try std.fmt.allocPrint(arena, "/{s}", .{rel});
    if (esp.statFile(io, rel, .{})) |_| return loader_path else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }
    try esp.createDirPath(io, kernels_dir);
    const tmp = try std.fmt.allocPrint(arena, "{s}.tmp", .{rel});
    try src_dir.copyFile(src_path, esp, tmp, io, .{});
    try esp.rename(tmp, esp, rel, io);
    return loader_path;
}

/// Deletes kernel images no remaining entry refers to.
pub fn pruneKernels(arena: Allocator, io: Io, esp: Io.Dir, entries: []const Entry, also_keep: []const []const u8) !void {
    var dir = esp.openDir(io, kernels_dir, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer dir.close(io);
    var doomed: std.ArrayList([]const u8) = .empty;
    var it = dir.iterate();
    outer: while (try it.next(io)) |e| {
        const loader_path = try std.fmt.allocPrint(arena, "/" ++ kernels_dir ++ "/{s}", .{e.name});
        for (entries) |entry| if (std.mem.eql(u8, entry.kernel, loader_path)) continue :outer;
        for (also_keep) |keep| if (std.mem.eql(u8, keep, loader_path)) continue :outer;
        try doomed.append(arena, try arena.dupe(u8, e.name));
    }
    for (doomed.items) |name| try dir.deleteFile(io, name);
}

/// Rewrites kernel options for another deployment: only the subvolume changes.
pub fn optionsFor(arena: Allocator, options: []const u8, id: u32) ![]const u8 {
    const marker = "subvol=joe/deploy/";
    const at = std.mem.indexOf(u8, options, marker) orelse return error.NoSubvolumeOption;
    var end = at + marker.len;
    while (end < options.len and std.ascii.isDigit(options[end])) end += 1;
    return std.fmt.allocPrint(arena, "{s}{s}{d}{s}", .{ options[0..at], marker, id, options[end..] });
}

/// The deployment named by a kernel command line, if it is a joe deployment.
pub fn deploymentOf(cmdline: []const u8) ?u32 {
    const marker = "subvol=joe/deploy/";
    const at = std.mem.indexOf(u8, cmdline, marker) orelse return null;
    var end = at + marker.len;
    while (end < cmdline.len and std.ascii.isDigit(cmdline[end])) end += 1;
    return std.fmt.parseInt(u32, cmdline[at + marker.len .. end], 10) catch null;
}

const testing = std.testing;

test "entry file names" {
    try testing.expectEqual(@as(?u32, null), parseName("joe-7.conf").?.tries_left);
    try testing.expectEqual(@as(u32, 7), parseName("joe-7.conf").?.id);
    const fresh = parseName("joe-12+3.conf").?;
    try testing.expectEqual(@as(u32, 12), fresh.id);
    try testing.expectEqual(@as(?u32, 3), fresh.tries_left);
    try testing.expectEqual(@as(u32, 0), fresh.tries_done);
    const used = parseName("joe-12+0-3.conf").?;
    try testing.expectEqual(@as(?u32, 0), used.tries_left);
    try testing.expectEqual(@as(u32, 3), used.tries_done);
    try testing.expect(parseName("arch.conf") == null);
    try testing.expect(parseName("joe-x.conf") == null);
    try testing.expect(parseName("joe-1.conf.tmp") == null);
    try testing.expect(parseName(".joe-1+3.conf.tmp") == null);
}

test "write, list, order and remove entries" {
    const io = testing.io;
    var arena_state: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var tmp = testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    const esp = tmp.dir;
    const opts = "root=PARTUUID=abc rootfstype=btrfs rootflags=subvol=joe/deploy/1 rw rootwait panic=10";

    try testing.expectEqual(@as(usize, 0), (try list(arena, io, esp)).len);
    try write(arena, io, esp, .{ .id = 1, .priority = 1, .kernel = "/joe/kernels/a.efi", .options = opts, .counted = false });
    try write(arena, io, esp, .{ .id = 2, .priority = 2, .kernel = "/joe/kernels/a.efi", .options = try optionsFor(arena, opts, 2), .counted = true });

    var entries = try list(arena, io, esp);
    try testing.expectEqual(@as(usize, 2), entries.len);
    try testing.expectEqual(@as(u32, 2), defaultEntry(entries).?.id);
    try testing.expectEqual(Health.trial, entries[0].health());
    try testing.expectEqual(Health.good, entries[1].health());
    try testing.expect(std.mem.indexOf(u8, entries[0].options, "subvol=joe/deploy/2 rw") != null);
    try testing.expectEqualStrings("joe-2+3.conf", entries[0].file_name);

    // What systemd-boot does after three failed attempts.
    try esp.rename(entries_dir ++ "/joe-2+3.conf", esp, entries_dir ++ "/joe-2+0-3.conf", io);
    entries = try list(arena, io, esp);
    try testing.expectEqual(Health.bad, find(entries, 2).?.health());
    try testing.expectEqual(@as(u32, 1), defaultEntry(entries).?.id);

    // Rollback and activation are the same primitive: take the top priority.
    try write(arena, io, esp, .{ .id = 3, .priority = 3, .kernel = "/joe/kernels/b.efi", .options = try optionsFor(arena, opts, 3), .counted = false });
    try write(arena, io, esp, .{ .id = 1, .priority = highestPriority(try list(arena, io, esp)) + 1, .kernel = "/joe/kernels/a.efi", .options = opts, .counted = false });
    entries = try list(arena, io, esp);
    try testing.expectEqual(@as(u32, 1), defaultEntry(entries).?.id);
    try testing.expectEqual(@as(u64, 4), find(entries, 1).?.priority);

    // Rewriting an entry leaves exactly one file for that deployment.
    try write(arena, io, esp, .{ .id = 2, .priority = 9, .kernel = "/joe/kernels/a.efi", .options = opts, .counted = false });
    entries = try list(arena, io, esp);
    try testing.expectEqual(@as(usize, 3), entries.len);
    try testing.expectEqual(Health.good, find(entries, 2).?.health());

    try remove(arena, io, esp, 2);
    try testing.expect(find(try list(arena, io, esp), 2) == null);
}

test "kernels are stored by content and pruned when unreferenced" {
    const io = testing.io;
    var arena_state: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var tmp = testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.createDirPath(io, "esp");
    var esp = try tmp.dir.openDir(io, "esp", .{ .iterate = true });
    defer esp.close(io);

    try tmp.dir.writeFile(io, .{ .sub_path = "vmlinuz-a", .data = "kernel a" });
    try tmp.dir.writeFile(io, .{ .sub_path = "vmlinuz-b", .data = "kernel b" });
    const a = try installKernel(arena, io, esp, tmp.dir, "vmlinuz-a");
    const a_again = try installKernel(arena, io, esp, tmp.dir, "vmlinuz-a");
    const b = try installKernel(arena, io, esp, tmp.dir, "vmlinuz-b");
    try testing.expectEqualStrings(a, a_again);
    try testing.expect(!std.mem.eql(u8, a, b));
    try testing.expect(std.mem.startsWith(u8, a, "/joe/kernels/"));

    try write(arena, io, esp, .{ .id = 1, .priority = 1, .kernel = a, .options = "subvol=joe/deploy/1", .counted = false });
    try pruneKernels(arena, io, esp, try list(arena, io, esp), &.{});
    _ = try esp.statFile(io, a[1..], .{});
    try testing.expectError(error.FileNotFound, esp.statFile(io, b[1..], .{}));
}

test "command line helpers" {
    var arena_state: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    try testing.expectEqual(@as(?u32, 14), deploymentOf("root=PARTUUID=x rootflags=subvol=joe/deploy/14 rw"));
    try testing.expectEqual(@as(?u32, null), deploymentOf("root=/dev/sda2 rw"));
    try testing.expectEqualStrings(
        "root=PARTUUID=x rootflags=subvol=joe/deploy/205 rw quiet",
        try optionsFor(arena, "root=PARTUUID=x rootflags=subvol=joe/deploy/9 rw quiet", 205),
    );
    try testing.expectError(error.NoSubvolumeOption, optionsFor(arena, "root=/dev/sda2", 2));
}
