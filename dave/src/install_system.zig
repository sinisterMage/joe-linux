//! Installing joe Linux onto a whole disk: `dave install-system`, the back
//! end of the graphical installer (installer/), run as root on the live
//! medium.
//!
//! An installation is the same thing as a disk image (provision.zig) made on
//! a real disk instead of from files: the disk gets a new GPT with an EFI
//! system partition and a btrfs root, the first deployment is one dave
//! transaction from the repository on the medium, and the ESP is written as
//! for an image. What an image cannot do and an installation can, because it
//! runs as root on the machine it installs: the files are sealed as they are
//! installed (so the first boot has nothing to seal), and the firmware is told
//! where the boot loader is.
//!
//! The medium (iso.zig) says what to install, in joe/install.zon, and holds
//! the repositories in joe/repos/<name>/. The installed system is configured
//! with the repositories the live system itself uses (its own
//! /etc/dave/repos.zon and keys), so it takes upgrades from where the live
//! system would have.
//!
//! This file holds what an installation needs that is not dave's ordinary
//! work: finding the disks it may use, partitioning, formatting and mounting.
//! main.zig runs the steps in order, with the transaction and sealing in
//! between, and reports progress.

const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const linux = std.os.linux;
const provision = @import("provision.zig");
const command = @import("command.zig");
const btrfs = @import("btrfs.zig");
const deploy = @import("deploy.zig");
const manifest = @import("manifest.zig");

pub const medium_mount = "/run/live/medium";
pub const medium_dir = medium_mount ++ "/joe";
pub const install_file = "install.zon";
pub const repos_dir = "repos";
pub const min_disk_size: u64 = 20 * 1000 * 1000 * 1000;
pub const top_mount = "/run/dave/install/top";
pub const target_mount = "/run/dave/install/target";

/// joe/install.zon on the medium.
pub const Medium = struct {
    /// What the installer installs: the image spec's `.iso.payload`.
    packages: []const []const u8,
};

pub fn parseMedium(arena: Allocator, text: []const u8) !Medium {
    return manifest.parseZon(Medium, arena, text) catch error.InvalidMedium;
}

/// A file system found on a disk, so that a person choosing a disk can
/// recognise what they would lose.
pub const Content = struct {
    name: []const u8,
    fstype: []const u8,
    label: []const u8,
    size: u64,
};

pub const Disk = struct {
    /// What to pass as --disk: a /dev/disk/by-id path where the disk has
    /// one, which names this disk and no other however devices are numbered.
    path: []const u8,
    device: []const u8,
    size: u64,
    model: []const u8,
    transport: []const u8,
    removable: bool,
    usable: bool,
    /// Why it is not usable, for the person choosing.
    reason: []const u8 = "",
    contents: []const Content = &.{},
};

/// A /dev/disk/by-id link and the device name it points at ("vda").
pub const Link = struct {
    device: []const u8,
    path: []const u8,
};

/// Every /dev/disk/by-id link to a whole disk.
pub fn readById(arena: Allocator, io: Io) ![]Link {
    var out: std.ArrayList(Link) = .empty;
    var dir = Io.Dir.cwd().openDir(io, "/dev/disk/by-id", .{ .iterate = true }) catch return out.items;
    defer dir.close(io);
    var it = dir.iterate();
    while (try it.next(io)) |e| {
        if (std.mem.indexOf(u8, e.name, "-part") != null) continue;
        var buf: [std.fs.max_path_bytes]u8 = undefined;
        const n = dir.readLink(io, e.name, &buf) catch continue;
        try out.append(arena, .{
            .device = try arena.dupe(u8, std.fs.path.basename(buf[0..n])),
            .path = try std.fmt.allocPrint(arena, "/dev/disk/by-id/{s}", .{e.name}),
        });
    }
    return out.items;
}

/// The most telling stable name of a disk: one built from its model and
/// serial number rather than a WWN or EUI, which say nothing to a person.
fn stablePath(links: []const Link, device: []const u8) ?[]const u8 {
    var best: ?[]const u8 = null;
    for (links) |l| {
        if (!std.mem.eql(u8, l.device, device)) continue;
        const name = std.fs.path.basename(l.path);
        const opaque_name = std.mem.startsWith(u8, name, "wwn-") or std.mem.startsWith(u8, name, "nvme-eui.") or
            std.mem.startsWith(u8, name, "nvme-nvme.");
        if (best == null or (!opaque_name and std.mem.order(u8, l.path, best.?) == .lt) or
            (!opaque_name and isOpaque(best.?))) best = l.path;
    }
    return best;
}

fn isOpaque(path: []const u8) bool {
    const name = std.fs.path.basename(path);
    return std.mem.startsWith(u8, name, "wwn-") or std.mem.startsWith(u8, name, "nvme-eui.") or
        std.mem.startsWith(u8, name, "nvme-nvme.");
}

fn field(obj: std.json.ObjectMap, key: []const u8) []const u8 {
    return switch (obj.get(key) orelse return "") {
        .string => |s| s,
        else => "",
    };
}

/// lsblk prints booleans as true/false or, in older versions, "0"/"1".
fn flag(obj: std.json.ObjectMap, key: []const u8) bool {
    return switch (obj.get(key) orelse return false) {
        .bool => |b| b,
        .string => |s| std.mem.eql(u8, s, "1"),
        .integer => |i| i != 0,
        else => false,
    };
}

fn number(obj: std.json.ObjectMap, key: []const u8) u64 {
    return switch (obj.get(key) orelse return 0) {
        .integer => |i| @intCast(@max(i, 0)),
        .string => |s| std.fmt.parseInt(u64, s, 10) catch 0,
        else => 0,
    };
}

fn mountPoints(obj: std.json.ObjectMap) []const std.json.Value {
    const v = obj.get("mountpoints") orelse return &.{};
    return switch (v) {
        .array => |a| a.items,
        else => &.{},
    };
}

/// The output lsblk(8) is asked for.
pub const lsblk_argv = [_][]const u8{ "lsblk", "--json", "--bytes", "--output", "NAME,PATH,SIZE,TYPE,MODEL,TRAN,RM,RO,FSTYPE,LABEL,MOUNTPOINTS" };

/// The disks of `lsblk_json`, each with whether it may be installed on.
/// `medium` is the device the live medium is mounted from (a disk or one of
/// its partitions); that disk is never offered.
pub fn parseDisks(arena: Allocator, lsblk_json: []const u8, links: []const Link, medium: ?[]const u8) ![]Disk {
    const doc = std.json.parseFromSliceLeaky(std.json.Value, arena, lsblk_json, .{}) catch return error.InvalidLsblk;
    const devices = switch (doc) {
        .object => |o| switch (o.get("blockdevices") orelse return error.InvalidLsblk) {
            .array => |a| a.items,
            else => return error.InvalidLsblk,
        },
        else => return error.InvalidLsblk,
    };
    var out: std.ArrayList(Disk) = .empty;
    for (devices) |v| {
        const obj = switch (v) {
            .object => |o| o,
            else => continue,
        };
        if (!std.mem.eql(u8, field(obj, "type"), "disk")) continue;
        const name = field(obj, "name");
        if (std.mem.startsWith(u8, name, "zram")) continue;
        const device = field(obj, "path");

        var contents: std.ArrayList(Content) = .empty;
        var holds_medium = medium != null and std.mem.eql(u8, medium.?, device);
        var in_use: ?[]const u8 = null;
        if (fsOf(obj)) |c| try contents.append(arena, c);
        in_use = mountedAt(obj);
        if (obj.get("children")) |children| if (children == .array) for (children.array.items) |cv| {
            const child = switch (cv) {
                .object => |o| o,
                else => continue,
            };
            if (medium != null and std.mem.eql(u8, medium.?, field(child, "path"))) holds_medium = true;
            if (fsOf(child)) |c| try contents.append(arena, c);
            if (in_use == null) in_use = mountedAt(child);
        };

        const size = number(obj, "size");
        var disk: Disk = .{
            .path = stablePath(links, name) orelse device,
            .device = device,
            .size = size,
            .model = std.mem.trim(u8, field(obj, "model"), " "),
            .transport = field(obj, "tran"),
            .removable = flag(obj, "rm"),
            .usable = true,
            .contents = contents.items,
        };
        if (holds_medium) {
            disk.usable = false;
            disk.reason = "it holds the medium this system is running from";
        } else if (flag(obj, "ro")) {
            disk.usable = false;
            disk.reason = "it is read-only";
        } else if (size < min_disk_size) {
            disk.usable = false;
            disk.reason = "it is smaller than 20 GB";
        } else if (in_use) |point| {
            disk.usable = false;
            disk.reason = try std.fmt.allocPrint(arena, "part of it is in use ({s})", .{point});
        }
        try out.append(arena, disk);
    }
    return out.items;
}

fn fsOf(obj: std.json.ObjectMap) ?Content {
    const fstype = field(obj, "fstype");
    if (fstype.len == 0) return null;
    return .{ .name = field(obj, "name"), .fstype = fstype, .label = field(obj, "label"), .size = number(obj, "size") };
}

/// Where a device is mounted, if anywhere; lsblk lists null for a device
/// that is not.
fn mountedAt(obj: std.json.ObjectMap) ?[]const u8 {
    for (mountPoints(obj)) |p| switch (p) {
        .string => |s| return if (std.mem.eql(u8, s, "[SWAP]")) "swap" else s,
        else => {},
    };
    return null;
}

/// The device a mount point is mounted from, from /proc/self/mountinfo.
pub fn mountSource(mountinfo: []const u8, mount_point: []const u8) ?[]const u8 {
    var found: ?[]const u8 = null;
    var lines = std.mem.tokenizeScalar(u8, mountinfo, '\n');
    while (lines.next()) |line| {
        const sep = std.mem.indexOf(u8, line, " - ") orelse continue;
        var head = std.mem.tokenizeScalar(u8, line[0..sep], ' ');
        var n: usize = 0;
        var point: []const u8 = "";
        while (head.next()) |f| : (n += 1) {
            if (n == 4) point = f;
        }
        if (!std.mem.eql(u8, point, mount_point)) continue;
        var tail = std.mem.tokenizeScalar(u8, line[sep + 3 ..], ' ');
        _ = tail.next() orelse continue;
        found = tail.next() orelse continue;
    }
    return found;
}

/// The steps of an installation that touch the disk. Each failure leaves a
/// sentence in `diag`.
pub const Disks = struct {
    arena: Allocator,
    io: Io,
    diag: command.Diagnostic = .{},

    fn fail(d: *Disks, comptime fmt: []const u8, args: anytype) error{InstallFailed} {
        d.diag.message = std.fmt.allocPrint(d.arena, fmt, args) catch "out of memory";
        return error.InstallFailed;
    }

    fn run(d: *Disks, argv: []const []const u8, input: ?[]const u8) !void {
        _ = command.run(d.arena, d.io, argv, .{ .input = input }, &d.diag) catch return error.InstallFailed;
    }

    /// Erases `device` and writes the plan's partition table. Returns the
    /// paths of the new ESP and root partitions, by their GPT UUIDs, which
    /// is how udev names them however the disk's partitions are numbered.
    pub fn partition(d: *Disks, device: []const u8, plan: provision.Plan) !struct { esp: []const u8, root: []const u8 } {
        // Old signatures would otherwise be found again by blkid and udev
        // (an old file system's label, an old RAID member) and confuse what
        // comes next, in this system or the installed one.
        try d.run(&.{ "wipefs", "--all", "--force", device }, null);
        try d.run(&.{ "sfdisk", "--quiet", "--wipe", "always", device }, try provision.sfdiskScript(d.arena, plan));
        const esp = try std.fmt.allocPrint(d.arena, "/dev/disk/by-partuuid/{s}", .{plan.esp_uuid});
        const root = try std.fmt.allocPrint(d.arena, "/dev/disk/by-partuuid/{s}", .{plan.root_uuid});
        var tries: usize = 0;
        while (tries < 30) : (tries += 1) {
            d.run(&.{ "udevadm", "settle", "--timeout=10" }, null) catch {};
            const have_esp = if (Io.Dir.cwd().statFile(d.io, esp, .{})) |_| true else |_| false;
            const have_root = if (Io.Dir.cwd().statFile(d.io, root, .{})) |_| true else |_| false;
            if (have_esp and have_root) return .{ .esp = esp, .root = root };
            try d.io.sleep(.fromMilliseconds(500), .awake);
        }
        return d.fail("the new partitions of {s} did not appear", .{device});
    }

    pub fn format(d: *Disks, esp: []const u8, root: []const u8) !void {
        try d.run(&.{ "mkfs.vfat", "-F", "32", "-n", provision.esp_label, esp }, null);
        try d.run(&.{ "mkfs.btrfs", "--quiet", "--force", "--label", provision.root_label, root }, null);
    }

    /// `options` are the file system's own; flags such as noatime are
    /// `flags` (mount(8) separates the two; the system call does not).
    fn mountAt(d: *Disks, source: []const u8, point: []const u8, fstype: []const u8, flags: u32, options: []const u8) !void {
        Io.Dir.cwd().createDirPath(d.io, point) catch |err| return d.fail("cannot create {s}: {t}", .{ point, err });
        const rc = linux.mount(
            try d.arena.dupeSentinel(u8, source, 0),
            try d.arena.dupeSentinel(u8, point, 0),
            try d.arena.dupeSentinel(u8, fstype, 0),
            flags,
            @intFromPtr((try d.arena.dupeSentinel(u8, options, 0)).ptr),
        );
        if (linux.errno(rc) != .SUCCESS) return d.fail("cannot mount {s} at {s}: {t}", .{ source, point, linux.errno(rc) });
    }

    /// Lays out the btrfs file system as provision.zig describes and mounts
    /// the first deployment at `target_mount`, with /var, /home and /efi
    /// mounted in it where they will be mounted when it runs.
    pub fn mountTarget(d: *Disks, esp: []const u8, root: []const u8) !void {
        try d.mountAt(root, top_mount, "btrfs", 0, "subvolid=5");
        {
            var top = Io.Dir.cwd().openDir(d.io, top_mount, .{ .iterate = true }) catch |err|
                return d.fail("cannot open {s}: {t}", .{ top_mount, err });
            defer top.close(d.io);
            try top.createDirPath(d.io, deploy.deploy_dir);
            var parent = try top.openDir(d.io, deploy.deploy_dir, .{ .iterate = true });
            defer parent.close(d.io);
            btrfs.createSubvolume(parent, std.fs.path.basename(provision.first_deployment_path)) catch |err|
                return d.fail("cannot create the subvolume {s}: {t}", .{ provision.first_deployment_path, err });
            for (provision.shared_subvolumes) |name| {
                btrfs.createSubvolume(top, name) catch |err| return d.fail("cannot create the subvolume {s}: {t}", .{ name, err });
            }
        }
        try d.mountAt(root, target_mount, "btrfs", 0, "subvol=" ++ provision.first_deployment_path);
        for (provision.shared_subvolumes) |name| {
            const point = try std.fs.path.join(d.arena, &.{ target_mount, name });
            try d.mountAt(root, point, "btrfs", linux.MS.NOATIME, try std.fmt.allocPrint(d.arena, "subvol={s}", .{name}));
        }
        try d.mountAt(esp, target_mount ++ "/" ++ provision.esp_mount, "vfat", 0, "umask=0077");
    }

    /// Unmounts whatever of the target is mounted, innermost first.
    pub fn unmountTarget(d: *Disks) void {
        const points = [_][]const u8{
            target_mount ++ "/" ++ provision.esp_mount,
            target_mount ++ "/home",
            target_mount ++ "/var",
            target_mount,
            top_mount,
        };
        for (points) |point| _ = linux.umount2(@ptrCast(d.arena.dupeSentinel(u8, point, 0) catch continue), 0);
    }
};

const testing = std.testing;

const sample_lsblk =
    \\{"blockdevices": [
    \\  {"name":"sr0","path":"/dev/sr0","size":2147483648,"type":"rom","model":"QEMU DVD-ROM","tran":"sata","rm":true,"ro":false,"fstype":"iso9660","label":"JOE_LIVE","mountpoints":["/run/live/medium"]},
    \\  {"name":"vda","path":"/dev/vda","size":42949672960,"type":"disk","model":null,"tran":null,"rm":false,"ro":false,"fstype":null,"label":null,"mountpoints":[null],
    \\   "children":[{"name":"vda1","path":"/dev/vda1","size":1073741824,"type":"part","model":null,"tran":null,"rm":false,"ro":false,"fstype":"ntfs","label":"Windows","mountpoints":[null]}]},
    \\  {"name":"sda","path":"/dev/sda","size":16008609792,"type":"disk","model":"Flash Disk  ","tran":"usb","rm":"1","ro":"0","fstype":"iso9660","label":"JOE_LIVE","mountpoints":[],
    \\   "children":[{"name":"sda1","path":"/dev/sda1","size":2147483648,"type":"part","fstype":"iso9660","label":"JOE_LIVE","mountpoints":["/run/live/medium"]}]},
    \\  {"name":"nvme0n1","path":"/dev/nvme0n1","size":512110190592,"type":"disk","model":"Some SSD","tran":"nvme","rm":false,"ro":false,"fstype":null,"label":null,"mountpoints":[],
    \\   "children":[{"name":"nvme0n1p2","path":"/dev/nvme0n1p2","size":511000000000,"type":"part","fstype":"swap","label":null,"mountpoints":["[SWAP]"]}]},
    \\  {"name":"vdb","path":"/dev/vdb","size":8589934592,"type":"disk","model":null,"tran":null,"rm":false,"ro":false,"fstype":null,"label":null,"mountpoints":[]},
    \\  {"name":"zram0","path":"/dev/zram0","size":8589934592,"type":"disk","rm":false,"ro":false,"fstype":"swap","mountpoints":["[SWAP]"]}
    \\]}
;

test "disks are offered with what is on them, and refused with a reason" {
    var arena_state: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const links = [_]Link{
        .{ .device = "nvme0n1", .path = "/dev/disk/by-id/nvme-eui.0025385b71b0" },
        .{ .device = "nvme0n1", .path = "/dev/disk/by-id/nvme-Some_SSD_S4EVNF0M" },
        .{ .device = "sda", .path = "/dev/disk/by-id/usb-Flash_Disk-0:0" },
    };
    const disks = try parseDisks(arena, sample_lsblk, &links, "/dev/sda1");
    try testing.expectEqual(@as(usize, 4), disks.len);

    // A virtual disk with no serial number has no by-id name.
    try testing.expectEqualStrings("/dev/vda", disks[0].path);
    try testing.expect(disks[0].usable);
    try testing.expectEqual(@as(usize, 1), disks[0].contents.len);
    try testing.expectEqualStrings("Windows", disks[0].contents[0].label);

    try testing.expectEqualStrings("/dev/disk/by-id/usb-Flash_Disk-0:0", disks[1].path);
    try testing.expect(!disks[1].usable);
    try testing.expect(disks[1].removable);
    try testing.expectEqualStrings("Flash Disk", disks[1].model);
    try testing.expect(std.mem.indexOf(u8, disks[1].reason, "medium") != null);

    try testing.expectEqualStrings("/dev/disk/by-id/nvme-Some_SSD_S4EVNF0M", disks[2].path);
    try testing.expect(!disks[2].usable);
    try testing.expectEqualStrings("part of it is in use (swap)", disks[2].reason);

    try testing.expect(!disks[3].usable);
    try testing.expectEqualStrings("it is smaller than 20 GB", disks[3].reason);
}

test "the device a mount point comes from" {
    const info =
        \\24 1 0:22 / / rw,relatime - overlay overlay rw,lowerdir=/run/live/lower
        \\30 24 11:0 / /run/live/medium ro,relatime - iso9660 /dev/sr0 ro
        \\31 24 7:0 / /run/live/lower ro,relatime - erofs /dev/loop0 ro
        \\
    ;
    try testing.expectEqualStrings("/dev/sr0", mountSource(info, medium_mount).?);
    try testing.expect(mountSource(info, "/nowhere") == null);
}

test "the medium says what to install" {
    var arena_state: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena_state.deinit();
    const m = try parseMedium(arena_state.allocator(), ".{ .packages = .{ \"joe-desktop\" } }");
    try testing.expectEqualStrings("joe-desktop", m.packages[0]);
}

test "the disk steps compile" {
    _ = &Disks.partition;
    _ = &Disks.format;
    _ = &Disks.mountTarget;
    _ = &Disks.unmountTarget;
    _ = &readById;
}
