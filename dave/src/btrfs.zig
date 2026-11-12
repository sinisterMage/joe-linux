//! The handful of btrfs operations dave needs, issued directly as ioctls so
//! the package manager has no runtime dependency on btrfs-progs.
//!
//! Every `Io.Dir` passed in must have been opened with `.iterate = true`:
//! without it the descriptor is path-only and the kernel rejects ioctls on it.

const std = @import("std");
const Io = std.Io;
const linux = std.os.linux;

const ioctl_magic = 0x94;
const name_max = 4040;

const VolArgsV2 = extern struct {
    fd: i64,
    transid: u64 = 0,
    flags: u64 = 0,
    unused: [4]u64 = @splat(0),
    name: [name_max]u8 = @splat(0),
};

const VolArgs = extern struct {
    fd: i64 = 0,
    name: [4088]u8 = @splat(0),
};

const Timespec = extern struct {
    sec: u64,
    nsec: u32,
};

const SubvolInfoArgs = extern struct {
    treeid: u64,
    name: [256]u8,
    parent_id: u64,
    dirid: u64,
    generation: u64,
    flags: u64,
    uuid: [16]u8,
    parent_uuid: [16]u8,
    received_uuid: [16]u8,
    ctransid: u64,
    otransid: u64,
    stransid: u64,
    rtransid: u64,
    ctime: Timespec,
    otime: Timespec,
    stime: Timespec,
    rtime: Timespec,
    reserved: [8]u64,
};

const RootRefArgs = extern struct {
    min_treeid: u64 = 0,
    rootref: [255]extern struct { treeid: u64, dirid: u64 } = undefined,
    num_items: u8 = 0,
    @"align": [7]u8 = @splat(0),
};

comptime {
    std.debug.assert(@sizeOf(VolArgsV2) == 4096);
    std.debug.assert(@sizeOf(VolArgs) == 4096);
    std.debug.assert(@sizeOf(SubvolInfoArgs) == 504);
    std.debug.assert(@sizeOf(RootRefArgs) == 4096);
}

const Direction = enum(u32) { write = 1, read = 2, read_write = 3 };

fn request(dir: Direction, nr: u32, comptime T: type) u32 {
    return (@intFromEnum(dir) << 30) | (@as(u32, @sizeOf(T)) << 16) | (ioctl_magic << 8) | nr;
}

const SNAP_DESTROY = request(.write, 15, VolArgs);
const SNAP_CREATE_V2 = request(.write, 23, VolArgsV2);
const SUBVOL_CREATE_V2 = request(.write, 24, VolArgsV2);
const GET_SUBVOL_INFO = request(.read, 60, SubvolInfoArgs);
const GET_SUBVOL_ROOTREF = request(.read_write, 61, RootRefArgs);

pub const Error = error{
    NotBtrfs,
    AlreadyExists,
    PermissionDenied,
    NameTooLong,
    NotFound,
    NoSpace,
    ReadOnly,
    NotEmpty,
    /// The directory was not opened with `.iterate = true`.
    BadDescriptor,
    Unexpected,
};

fn check(rc: usize) Error!void {
    return switch (linux.errno(rc)) {
        .SUCCESS => {},
        .NOTTY, .INVAL, .OPNOTSUPP => error.NotBtrfs,
        .EXIST => error.AlreadyExists,
        .PERM, .ACCES => error.PermissionDenied,
        .NOENT => error.NotFound,
        .NOSPC, .DQUOT => error.NoSpace,
        .ROFS => error.ReadOnly,
        .NOTEMPTY => error.NotEmpty,
        .BADF => error.BadDescriptor,
        else => error.Unexpected,
    };
}

fn setName(buf: []u8, name: []const u8) Error!void {
    if (name.len == 0 or name.len >= buf.len or std.mem.indexOfScalar(u8, name, '/') != null) return error.NameTooLong;
    @memcpy(buf[0..name.len], name);
}

/// Creates an empty subvolume `name` inside `parent`.
pub fn createSubvolume(parent: Io.Dir, name: []const u8) Error!void {
    var args: VolArgsV2 = .{ .fd = 0 };
    try setName(&args.name, name);
    try check(linux.ioctl(parent.handle, SUBVOL_CREATE_V2, @intFromPtr(&args)));
}

/// Creates a writable snapshot of the subvolume `source` as `dest_parent/name`.
/// The snapshot is atomic: it captures one consistent instant of `source`.
pub fn snapshot(source: Io.Dir, dest_parent: Io.Dir, name: []const u8) Error!void {
    var args: VolArgsV2 = .{ .fd = source.handle };
    try setName(&args.name, name);
    try check(linux.ioctl(dest_parent.handle, SNAP_CREATE_V2, @intFromPtr(&args)));
}

/// Deletes the subvolume `parent/name` with everything in it. Requires
/// CAP_SYS_ADMIN unless the filesystem allows user subvolume removal.
pub fn destroySubvolume(parent: Io.Dir, name: []const u8) Error!void {
    var args: VolArgs = .{};
    try setName(&args.name, name);
    try check(linux.ioctl(parent.handle, SNAP_DESTROY, @intFromPtr(&args)));
}

/// Deletes a subvolume, falling back to removing its contents file by file
/// where the kernel refuses the direct operation to unprivileged users.
pub fn removeSubvolume(io: Io, parent: Io.Dir, name: []const u8) !void {
    destroySubvolume(parent, name) catch |err| switch (err) {
        error.NotFound => return,
        error.PermissionDenied => return parent.deleteTree(io, name),
        else => return err,
    };
}

pub const SubvolumeInfo = struct {
    id: u64,
    parent_id: u64,
    generation: u64,
};

/// Describes the subvolume that contains `dir`.
pub fn subvolumeInfo(dir: Io.Dir) Error!SubvolumeInfo {
    var args: SubvolInfoArgs = undefined;
    try check(linux.ioctl(dir.handle, GET_SUBVOL_INFO, @intFromPtr(&args)));
    return .{ .id = args.treeid, .parent_id = args.parent_id, .generation = args.generation };
}

/// Whether the subvolume containing `dir` has other subvolumes nested inside
/// it. A snapshot does not descend into nested subvolumes, so a root that has
/// them cannot be captured faithfully.
pub fn hasNestedSubvolumes(dir: Io.Dir) Error!bool {
    var args: RootRefArgs = .{};
    const rc = linux.ioctl(dir.handle, GET_SUBVOL_ROOTREF, @intFromPtr(&args));
    switch (linux.errno(rc)) {
        .SUCCESS, .OVERFLOW => return args.num_items > 0,
        else => {
            try check(rc);
            unreachable;
        },
    }
}

const testing = std.testing;

test "create, snapshot, inspect and remove subvolumes" {
    const io = testing.io;
    // ioctls need a real directory descriptor, which is what `iterate` asks for.
    var tmp = testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();

    createSubvolume(tmp.dir, "source") catch |err| switch (err) {
        // The build directory is not on btrfs; the VM tests cover this instead.
        error.NotBtrfs => return error.SkipZigTest,
        else => return err,
    };
    var source = try tmp.dir.openDir(io, "source", .{ .iterate = true });
    defer source.close(io);
    try source.writeFile(io, .{ .sub_path = "file", .data = "before" });

    try snapshot(source, tmp.dir, "copy");
    try testing.expectError(error.AlreadyExists, snapshot(source, tmp.dir, "copy"));
    try testing.expectError(error.NameTooLong, snapshot(source, tmp.dir, "a/b"));

    // The snapshot is independent of its source from that instant on.
    try source.writeFile(io, .{ .sub_path = "file", .data = "after" });
    var copy = try tmp.dir.openDir(io, "copy", .{ .iterate = true });
    defer copy.close(io);
    var buf: [16]u8 = undefined;
    try testing.expectEqualStrings("before", try copy.readFile(io, "file", &buf));
    try copy.writeFile(io, .{ .sub_path = "only-in-copy", .data = "x" });
    try testing.expectError(error.FileNotFound, source.statFile(io, "only-in-copy", .{}));

    const a = try subvolumeInfo(source);
    const b = try subvolumeInfo(copy);
    try testing.expect(a.id != b.id);
    const outer = try subvolumeInfo(tmp.dir);
    try testing.expect(outer.id != a.id);

    try testing.expect(!try hasNestedSubvolumes(source));
    try createSubvolume(source, "nested");
    try testing.expect(try hasNestedSubvolumes(source));

    try removeSubvolume(io, source, "nested");
    try removeSubvolume(io, tmp.dir, "copy");
    try testing.expectError(error.FileNotFound, tmp.dir.statFile(io, "copy", .{}));
    try removeSubvolume(io, tmp.dir, "copy"); // already gone: not an error
    try removeSubvolume(io, tmp.dir, "source");
}
