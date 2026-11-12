//! dave: the joe Linux package manager.

const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const linux = std.os.linux;

pub const version = @import("solver/version.zig");
pub const range = @import("solver/range.zig");
pub const pubgrub = @import("solver/pubgrub.zig");
pub const report = @import("solver/report.zig");
pub const manifest = @import("manifest.zig");
pub const archive = @import("archive.zig");
pub const db = @import("db.zig");
pub const txn = @import("txn.zig");
pub const repo = @import("repo.zig");
pub const resolve = @import("resolve.zig");
pub const btrfs = @import("btrfs.zig");
pub const boot = @import("boot.zig");
pub const triggers = @import("triggers.zig");
pub const deploy = @import("deploy.zig");
pub const builder = @import("builder.zig");

/// Indexes are signed and packages are checked against the signed index, so
/// transport security adds nothing dave relies on; leaving TLS out keeps the
/// static binary small until HTTPS repositories are supported.
pub const std_options: std.Options = .{ .http_disable_tls = true };

const dave_version = "0.1.0";
const top_mount = "/run/dave/top";
const lock_path = "/run/dave/lock";
const esp_path = "/efi";
const system_cache = "/var/cache/dave";
const boot_check_hooks = "etc/dave/boot-check.d";

const usage =
    \\Usage: dave <command> [options]
    \\
    \\Packages
    \\  install <package>...     Install packages (takes effect immediately)
    \\  remove <package>...      Remove packages (takes effect immediately)
    \\  upgrade [--reboot]       Prepare an upgrade of everything; applied on reboot
    \\  list                     List installed packages
    \\  info <package>           Describe a package
    \\  search <text>            Search the repositories
    \\
    \\System
    \\  status                   Show the running system and pending changes
    \\  rollback                 Return to the previous system on next boot
    \\  deployments [list]       List bootable system states
    \\  deployments pin <id>     Keep a deployment until unpinned
    \\  deployments unpin <id>
    \\  deployments gc           Delete deployments that are no longer needed
    \\
    \\Building
    \\  build <recipe> --buildroot DIR --sources DIR --work DIR --out DIR
    \\                                               Build a package from a recipe
    \\  pack --name N --version V --out DIR <tree>   Make a package from a directory
    \\  repo index <dir> [--key FILE]                Write and sign a repository index
    \\  key generate <basename>                      Create a signing key pair
    \\
    \\Options
    \\  --root DIR       Operate on the system installed at DIR instead of /
    \\  --cache DIR      Where downloaded indexes and packages are kept
    \\  --dry-run        Show what would be done and stop
    \\  --no-triggers    Do not run package triggers
    \\  --overwrite      Replace files that exist but belong to no package
    \\
;

const Options = struct {
    root: []const u8 = "/",
    cache: ?[]const u8 = null,
    dry_run: bool = false,
    no_triggers: bool = false,
    reboot: bool = false,
    overwrite: bool = false,
    keep_work: bool = false,
    buildroot: ?[]const u8 = null,
    sources: ?[]const u8 = null,
    work: ?[]const u8 = null,
    driver: ?[]const u8 = null,
    name: ?[]const u8 = null,
    pkg_version: ?[]const u8 = null,
    description: []const u8 = "",
    license: []const u8 = "",
    out: ?[]const u8 = null,
    key: ?[]const u8 = null,
    depends: std.ArrayList([]const u8) = .empty,
    conflicts: std.ArrayList([]const u8) = .empty,
    positional: std.ArrayList([]const u8) = .empty,
};

const Failure = error{Reported};

const App = struct {
    gpa: Allocator,
    arena: Allocator,
    io: Io,
    out: *Io.Writer,
    err: *Io.Writer,
    opts: Options = .{},

    // -- reporting ------------------------------------------------------------

    /// Prints a message for the user and returns the error that ends the command.
    fn fail(app: *App, comptime fmt: []const u8, args: anytype) Failure {
        app.err.print("dave: " ++ fmt ++ "\n", args) catch {};
        return error.Reported;
    }

    fn say(app: *App, comptime fmt: []const u8, args: anytype) !void {
        try app.out.print(fmt ++ "\n", args);
    }

    // -- argument parsing -----------------------------------------------------

    fn parseArgs(app: *App, args: []const []const u8) !void {
        var i: usize = 0;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (!std.mem.startsWith(u8, arg, "--")) {
                try app.opts.positional.append(app.arena, arg);
                continue;
            }
            if (std.mem.eql(u8, arg, "--dry-run")) {
                app.opts.dry_run = true;
            } else if (std.mem.eql(u8, arg, "--no-triggers")) {
                app.opts.no_triggers = true;
            } else if (std.mem.eql(u8, arg, "--reboot")) {
                app.opts.reboot = true;
            } else if (std.mem.eql(u8, arg, "--overwrite")) {
                app.opts.overwrite = true;
            } else if (std.mem.eql(u8, arg, "--keep-work")) {
                app.opts.keep_work = true;
            } else {
                i += 1;
                if (i >= args.len) return app.fail("{s} needs a value", .{arg});
                const value = args[i];
                if (std.mem.eql(u8, arg, "--root")) {
                    app.opts.root = value;
                } else if (std.mem.eql(u8, arg, "--cache")) {
                    app.opts.cache = value;
                } else if (std.mem.eql(u8, arg, "--buildroot")) {
                    app.opts.buildroot = value;
                } else if (std.mem.eql(u8, arg, "--sources")) {
                    app.opts.sources = value;
                } else if (std.mem.eql(u8, arg, "--work")) {
                    app.opts.work = value;
                } else if (std.mem.eql(u8, arg, "--driver")) {
                    app.opts.driver = value;
                } else if (std.mem.eql(u8, arg, "--name")) {
                    app.opts.name = value;
                } else if (std.mem.eql(u8, arg, "--version")) {
                    app.opts.pkg_version = value;
                } else if (std.mem.eql(u8, arg, "--description")) {
                    app.opts.description = value;
                } else if (std.mem.eql(u8, arg, "--license")) {
                    app.opts.license = value;
                } else if (std.mem.eql(u8, arg, "--out")) {
                    app.opts.out = value;
                } else if (std.mem.eql(u8, arg, "--key")) {
                    app.opts.key = value;
                } else if (std.mem.eql(u8, arg, "--depends")) {
                    try app.opts.depends.append(app.arena, value);
                } else if (std.mem.eql(u8, arg, "--conflicts")) {
                    try app.opts.conflicts.append(app.arena, value);
                } else {
                    return app.fail("unknown option {s}", .{arg});
                }
            }
        }
    }

    // -- dispatch -------------------------------------------------------------

    fn run(app: *App, args: []const []const u8) !void {
        if (args.len >= 1 and std.mem.eql(u8, args[0], triggers.chroot_command)) return app.chrootExec(args[1..]);
        try app.parseArgs(args);
        const pos = app.opts.positional.items;
        if (pos.len == 0) {
            try app.out.writeAll(usage);
            return;
        }
        const cmd = pos[0];
        const rest = pos[1..];
        if (std.mem.eql(u8, cmd, "help")) return app.out.writeAll(usage);
        if (std.mem.eql(u8, cmd, "version")) return app.say("dave {s}", .{dave_version});
        if (std.mem.eql(u8, cmd, "install")) return app.cmdChange(.install, rest);
        if (std.mem.eql(u8, cmd, "remove")) return app.cmdChange(.remove, rest);
        if (std.mem.eql(u8, cmd, "upgrade")) return app.cmdUpgrade();
        if (std.mem.eql(u8, cmd, "list")) return app.cmdList();
        if (std.mem.eql(u8, cmd, "info")) return app.cmdInfo(rest);
        if (std.mem.eql(u8, cmd, "search")) return app.cmdSearch(rest);
        if (std.mem.eql(u8, cmd, "status")) return app.cmdStatus();
        if (std.mem.eql(u8, cmd, "rollback")) return app.cmdRollback();
        if (std.mem.eql(u8, cmd, "deployments")) return app.cmdDeployments(rest);
        if (std.mem.eql(u8, cmd, "finalize")) return app.cmdFinalize();
        if (std.mem.eql(u8, cmd, "boot-check")) return app.cmdBootCheck();
        if (std.mem.eql(u8, cmd, "build")) return app.cmdBuild(rest);
        if (std.mem.eql(u8, cmd, "pack")) return app.cmdPack(rest);
        if (std.mem.eql(u8, cmd, "repo")) return app.cmdRepo(rest);
        if (std.mem.eql(u8, cmd, "key")) return app.cmdKey(rest);
        return app.fail("unknown command '{s}'; run 'dave help'", .{cmd});
    }

    // -- environment ----------------------------------------------------------

    fn openDir(app: *App, path: []const u8) !Io.Dir {
        return Io.Dir.cwd().openDir(app.io, path, .{ .iterate = true }) catch |e|
            return app.fail("cannot open {s}: {t}", .{ path, e });
    }

    /// Reads a whole file as a stream. Files under /proc report a size of zero,
    /// and for some of them (mountinfo) a size-based read returns nothing.
    fn readAbsolute(app: *App, path: []const u8) ?[]const u8 {
        var file = Io.Dir.cwd().openFile(app.io, path, .{}) catch return null;
        defer file.close(app.io);
        var buf: [4096]u8 = undefined;
        var reader = file.readerStreaming(app.io, &buf);
        return reader.interface.allocRemaining(app.arena, .limited(4 * 1024 * 1024)) catch null;
    }

    /// The id of the deployment this system is running from, if dave is being
    /// asked to act on the running system and that system uses deployments.
    fn runningDeployment(app: *App) ?u32 {
        if (!std.mem.eql(u8, app.opts.root, "/")) return null;
        return boot.deploymentOf(app.readAbsolute("/proc/cmdline") orelse return null);
    }

    const Mount = struct { source: []const u8, fstype: []const u8 };

    fn findMount(app: *App, mount_point: []const u8) ?Mount {
        const text = app.readAbsolute("/proc/self/mountinfo") orelse return null;
        var found: ?Mount = null;
        var lines = std.mem.tokenizeScalar(u8, text, '\n');
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
            const fstype = tail.next() orelse continue;
            const source = tail.next() orelse continue;
            // Later lines shadow earlier ones mounted on the same point.
            found = .{ .source = source, .fstype = fstype };
        }
        return found;
    }

    /// Mounts the top level of the root's btrfs filesystem where dave can
    /// reach every deployment, if it is not mounted there already.
    fn mountTop(app: *App) !void {
        if (app.findMount(top_mount) != null) return;
        const root = app.findMount("/") orelse return app.fail("cannot determine what / is mounted from", .{});
        if (!std.mem.eql(u8, root.fstype, "btrfs")) return app.fail("/ is {s}, not btrfs", .{root.fstype});
        Io.Dir.cwd().createDirPath(app.io, top_mount) catch |e| return app.fail("cannot create {s}: {t}", .{ top_mount, e });
        const source = try app.arena.dupeSentinel(u8, root.source, 0);
        const rc = linux.mount(source, top_mount, "btrfs", 0, @intFromPtr(@as([*:0]const u8, "subvolid=5")));
        if (linux.errno(rc) != .SUCCESS)
            return app.fail("cannot mount the top of {s} at {s}: {t}", .{ root.source, top_mount, linux.errno(rc) });
    }

    /// Only one dave may change the system at a time.
    fn lock(app: *App) !Io.File {
        Io.Dir.cwd().createDirPath(app.io, std.fs.path.dirname(lock_path).?) catch {};
        return Io.Dir.cwd().createFile(app.io, lock_path, .{ .truncate = false, .lock = .exclusive, .lock_nonblocking = true }) catch |e| switch (e) {
            error.WouldBlock => app.fail("another dave operation is in progress", .{}),
            else => app.fail("cannot take the lock {s}: {t}", .{ lock_path, e }),
        };
    }

    fn openSystem(app: *App, current: u32) !deploy.System {
        try app.mountTop();
        if (app.findMount(esp_path) == null) return app.fail("the EFI system partition is not mounted at {s}", .{esp_path});
        Io.Dir.cwd().createDirPath(app.io, system_cache) catch {};
        return .{
            .gpa = app.gpa,
            .arena = app.arena,
            .io = app.io,
            .top = try app.openDir(top_mount),
            .top_path = top_mount,
            .esp = try app.openDir(esp_path),
            .root = try app.openDir("/"),
            .cache = try app.openDir(system_cache),
            .current = current,
            .run_triggers = !app.opts.no_triggers,
        };
    }

    const Context = struct {
        root: Io.Dir,
        cache: Io.Dir,
        installed: []manifest.Manifest,
        world: []db.WorldEntry,
        config: repo.Config,
        trusted: []repo.PublicKey,
    };

    fn context(app: *App) !Context {
        const root = try app.openDir(app.opts.root);
        const cache_path = app.opts.cache orelse
            try std.fs.path.join(app.arena, &.{ app.opts.root, "var/cache/dave" });
        Io.Dir.cwd().createDirPath(app.io, cache_path) catch |e| return app.fail("cannot create {s}: {t}", .{ cache_path, e });
        return .{
            .root = root,
            .cache = try app.openDir(cache_path),
            .installed = db.load(app.arena, app.io, root) catch |e| return app.fail("the package database is unreadable: {t}", .{e}),
            .world = db.loadWorld(app.arena, app.io, root) catch |e| return app.fail("{s} is unreadable: {t}", .{ db.world_path, e }),
            .config = repo.loadConfig(app.arena, app.io, root) catch |e| return app.fail("{s} is unreadable: {t}", .{ repo.config_path, e }),
            .trusted = try repo.loadTrustedKeys(app.arena, app.io, root),
        };
    }

    fn candidates(app: *App, ctx: Context, refresh: bool) ![]repo.Candidate {
        if (ctx.config.repos.len == 0) return app.fail("no repositories are configured in {s}", .{repo.config_path});
        if (ctx.trusted.len == 0) return app.fail("no trusted keys in {s}; refusing to use unsigned repositories", .{repo.keys_path});
        if (!refresh) return repo.loadCached(app.arena, app.io, ctx.config, ctx.trusted, ctx.cache) catch |e|
            return app.fail("the cached repository index is unusable: {t}", .{e});
        return repo.refresh(app.gpa, app.arena, app.io, ctx.config, ctx.trusted, ctx.cache) catch |e| switch (e) {
            error.BadSignature => app.fail("a repository index is not signed by a trusted key; nothing was changed", .{}),
            else => app.fail("cannot refresh repositories: {t}", .{e}),
        };
    }

    fn solve(app: *App, request: resolve.Request) !resolve.Solution {
        var explanation: Io.Writer.Allocating = .init(app.arena);
        return resolve.resolve(app.arena, request, &explanation.writer) catch |e| switch (e) {
            error.NoSolution, error.InvalidDependency => {
                app.err.print("dave: this cannot be done.\n\n{s}", .{explanation.written()}) catch {};
                return error.Reported;
            },
            else => |other| return other,
        };
    }

    fn printPlan(app: *App, solution: resolve.Solution) !void {
        for (solution.install) |u| {
            if (u.from) |old| {
                try app.say("  upgrade  {s}  {s} -> {s}", .{ u.candidate.entry.name, old, u.candidate.entry.version });
            } else {
                try app.say("  install  {s}  {s}", .{ u.candidate.entry.name, u.candidate.entry.version });
            }
        }
        for (solution.remove) |m| try app.say("  remove   {s}  {s}", .{ m.name, m.version });
    }

    /// Downloads and verifies every package of a solution; returns their file
    /// names within the cache's package directory.
    fn download(app: *App, ctx: Context, solution: resolve.Solution) ![]const []const u8 {
        const names = try app.arena.alloc([]const u8, solution.install.len);
        for (solution.install, names) |u, *name| {
            _ = repo.ensurePackage(app.gpa, app.arena, app.io, u.candidate, ctx.cache) catch |e| switch (e) {
                error.ChecksumMismatch => return app.fail("{s} does not match the signed index; nothing was changed", .{u.candidate.entry.filename}),
                else => return app.fail("cannot fetch {s}: {t}", .{ u.candidate.entry.filename, e }),
            };
            name.* = u.candidate.entry.filename;
        }
        return names;
    }

    fn packageFiles(app: *App, ctx: Context, names: []const []const u8) ![]txn.PackageFile {
        const files = try app.arena.alloc(txn.PackageFile, names.len);
        for (names, files) |name, *f| {
            f.* = .{ .dir = ctx.cache, .sub_path = try std.fmt.allocPrint(app.arena, repo.packages_dir ++ "/{s}", .{name}) };
        }
        return files;
    }

    fn removeNames(app: *App, solution: resolve.Solution) ![]const []const u8 {
        const names = try app.arena.alloc([]const u8, solution.remove.len);
        for (solution.remove, names) |m, *n| n.* = m.name;
        return names;
    }

    /// Applies a solution directly to the root in `ctx` and runs triggers.
    fn applyNow(app: *App, ctx: Context, solution: resolve.Solution, files: []const []const u8) !void {
        var diag: txn.Diagnostic = .{};
        const result = txn.apply(app.gpa, app.arena, app.io, ctx.root, .{
            .install = try app.packageFiles(ctx, files),
            .remove = try app.removeNames(solution),
            .overwrite_unowned = app.opts.overwrite,
        }, &diag) catch |e| {
            if (diag.message.len > 0) return app.fail("{s}", .{diag.message});
            return app.fail("the transaction failed: {t}", .{e});
        };
        for (result.notes) |n| try app.say("note: {s}", .{n});
        if (app.opts.no_triggers) return;
        const wanted = try triggers.matching(app.arena, try triggers.load(app.arena, app.io, ctx.root), result.changed_paths);
        const live = std.mem.eql(u8, app.opts.root, "/");
        triggers.run(app.arena, app.io, wanted, .{
            .root = ctx.root,
            .chroot_path = if (live) null else try Io.Dir.cwd().realPathFileAlloc(app.io, app.opts.root, app.arena),
            .self_exe = "/proc/self/exe",
        }) catch |e| return app.fail("a package trigger failed: {t}", .{e});
    }

    // -- install / remove -----------------------------------------------------

    const ChangeKind = enum { install, remove };

    fn cmdChange(app: *App, kind: ChangeKind, names: []const []const u8) !void {
        if (names.len == 0) return app.fail("name at least one package", .{});
        const current = app.runningDeployment();
        var lock_file: ?Io.File = if (current != null) try app.lock() else null;
        defer if (lock_file) |*f| f.close(app.io);

        const ctx = try app.context();
        var world: std.ArrayList(db.WorldEntry) = .empty;
        try world.appendSlice(app.arena, ctx.world);
        for (names) |raw| {
            const dep = manifest.splitDependency(raw);
            if (!manifest.validName(dep.name)) return app.fail("'{s}' is not a valid package name", .{raw});
            const existing = for (world.items, 0..) |w, i| {
                if (std.mem.eql(u8, w.name, dep.name)) break i;
            } else null;
            switch (kind) {
                .install => if (existing) |i| {
                    if (dep.constraint.len > 0) world.items[i].constraint = dep.constraint;
                } else try world.append(app.arena, .{ .name = dep.name, .constraint = dep.constraint }),
                .remove => if (existing) |i| {
                    _ = world.orderedRemove(i);
                } else {
                    const is_installed = for (ctx.installed) |m| {
                        if (std.mem.eql(u8, m.name, dep.name)) break true;
                    } else false;
                    if (is_installed) return app.fail("{s} was not installed by request; it is here because another package needs it", .{dep.name});
                    return app.fail("{s} is not installed", .{dep.name});
                },
            }
        }

        const solution = try app.solve(.{
            .world = world.items,
            .installed = ctx.installed,
            .candidates = try app.candidates(ctx, kind == .install),
            .mode = .keep_installed,
        });
        if (solution.isEmpty()) {
            try db.saveWorld(app.arena, app.io, ctx.root, world.items);
            if (kind == .remove) {
                try app.say("Nothing was removed: other installed packages still need {s}.", .{names[0]});
            } else {
                try app.say("Already installed.", .{});
            }
            return;
        }
        try app.printPlan(solution);
        if (app.opts.dry_run) return;
        const files = try app.download(ctx, solution);

        var sys: ?deploy.System = null;
        var had_staged = false;
        if (current) |id| {
            for (solution.remove) |m| if (ownsKernel(m)) return app.fail("{s} provides the running kernel; it cannot be removed from a running system", .{m.name});
            for (files) |name| {
                const sub = try std.fmt.allocPrint(app.arena, repo.packages_dir ++ "/{s}", .{name});
                const m = try archive.readManifestOf(app.gpa, app.arena, app.io, ctx.cache, sub);
                if (ownsKernel(m)) return app.fail("{s} contains a kernel, which cannot change under a running system; use 'dave upgrade'", .{m.name});
            }
            sys = try app.openSystem(id);
            had_staged = (try sys.?.loadState()).staged != null;
            const reason = try std.fmt.allocPrint(app.arena, "before: dave {t} {s}", .{ kind, try std.mem.join(app.arena, " ", names) });
            const point = sys.?.rollbackPoint(reason) catch |e| {
                if (sys.?.diag.message.len > 0) return app.fail("{s}", .{sys.?.diag.message});
                return app.fail("cannot create a rollback point: {t}", .{e});
            };
            try app.say("Saved the current system as deployment {d}.", .{point});
        }

        app.applyNow(ctx, solution, files) catch |e| {
            if (current != null) app.err.writeAll("dave: the system may be partly changed; run 'dave rollback' and reboot to return to how it was.\n") catch {};
            return e;
        };
        try db.saveWorld(app.arena, app.io, ctx.root, world.items);
        try app.say("Done.", .{});

        if (sys) |*s| {
            _ = s.collectGarbage(deploy.default_keep) catch {};
            if (had_staged) {
                // The pending upgrade was computed for the old package set.
                try s.unstage();
                app.stageUpgrade(s, false) catch {
                    try app.say("The pending upgrade was dropped; run 'dave upgrade' again.", .{});
                };
            }
        }
    }

    fn ownsKernel(m: manifest.Manifest) bool {
        for (m.files) |f| {
            if (std.mem.startsWith(u8, f.path, "usr/lib/modules/") and std.mem.endsWith(u8, f.path, "/vmlinuz")) return true;
        }
        return false;
    }

    // -- upgrade --------------------------------------------------------------

    fn cmdUpgrade(app: *App) !void {
        const current = app.runningDeployment() orelse {
            // Not a deployment-managed system (an image being built, a
            // container): there is nothing to protect, so apply directly.
            const ctx = try app.context();
            const solution = try app.solve(.{
                .world = ctx.world,
                .installed = ctx.installed,
                .candidates = try app.candidates(ctx, true),
                .mode = .newest,
            });
            if (solution.isEmpty()) return app.say("Everything is up to date.", .{});
            try app.printPlan(solution);
            if (app.opts.dry_run) return;
            try app.applyNow(ctx, solution, try app.download(ctx, solution));
            return app.say("Done.", .{});
        };
        var lock_file = try app.lock();
        defer lock_file.close(app.io);
        var sys = try app.openSystem(current);
        try app.stageUpgrade(&sys, true);
        if (!app.opts.reboot or app.opts.dry_run) return;
        if ((try sys.loadState()).staged == null) return;
        const outcome = (try sys.finalize()) orelse return;
        if (!outcome.ok) return app.fail("the upgrade could not be applied: {s}", .{outcome.message});
        try app.say("Deployment {d} is ready. Rebooting.", .{outcome.deployment.?});
        try app.out.flush();
        var child = std.process.spawn(app.io, .{ .argv = &.{ "systemctl", "reboot" } }) catch |e|
            return app.fail("cannot reboot ({t}); reboot manually to finish", .{e});
        _ = try child.wait(app.io);
    }

    /// Solves, downloads, validates and records an upgrade of the running system.
    fn stageUpgrade(app: *App, sys: *deploy.System, refresh: bool) !void {
        const ctx = try app.context();
        const solution = try app.solve(.{
            .world = ctx.world,
            .installed = ctx.installed,
            .candidates = try app.candidates(ctx, refresh),
            .mode = .newest,
        });
        if (solution.isEmpty()) {
            try sys.unstage();
            return app.say("Everything is up to date.", .{});
        }
        try app.printPlan(solution);
        if (app.opts.dry_run) return;
        const files = try app.download(ctx, solution);
        const hash = try db.stateHash(app.arena, ctx.installed);
        const summary = try std.fmt.allocPrint(app.arena, "{d} to install or upgrade, {d} to remove", .{ solution.install.len, solution.remove.len });
        const result = sys.stage(.{
            .packages = files,
            .remove = try app.removeNames(solution),
            .db_hash = try app.arena.dupe(u8, &hash),
            .summary = summary,
        }) catch |e| {
            if (sys.diag.message.len > 0) return app.fail("the upgrade would not apply cleanly: {s}", .{sys.diag.message});
            return app.fail("the upgrade would not apply cleanly: {t}", .{e});
        };
        for (result.notes) |n| try app.say("note: {s}", .{n});
        try app.say("The upgrade is ready and will be applied when the system shuts down or reboots.", .{});
        try app.say("The running system has not been changed.", .{});
    }

    // -- queries --------------------------------------------------------------

    fn cmdList(app: *App) !void {
        const ctx = try app.context();
        for (ctx.installed) |m| {
            const requested = for (ctx.world) |w| {
                if (std.mem.eql(u8, w.name, m.name)) break true;
            } else false;
            try app.say("{s} {s}{s}", .{ m.name, m.version, if (requested) "" else "  (dependency)" });
        }
    }

    fn cmdInfo(app: *App, names: []const []const u8) !void {
        if (names.len != 1) return app.fail("name one package", .{});
        const ctx = try app.context();
        var found = false;
        for (ctx.installed) |m| {
            if (!std.mem.eql(u8, m.name, names[0])) continue;
            found = true;
            try app.say("{s} {s} (installed)", .{ m.name, m.version });
            if (m.description.len > 0) try app.say("  {s}", .{m.description});
            for (m.depends) |d| try app.say("  depends on {s}", .{d});
            try app.say("  {d} files", .{m.files.len});
        }
        const cands = repo.loadCached(app.arena, app.io, ctx.config, ctx.trusted, ctx.cache) catch &.{};
        for (cands) |c| {
            if (!std.mem.eql(u8, c.entry.name, names[0])) continue;
            found = true;
            try app.say("{s} {s} (available)", .{ c.entry.name, c.entry.version });
        }
        if (!found) return app.fail("no package named {s} is installed or available", .{names[0]});
    }

    fn cmdSearch(app: *App, terms: []const []const u8) !void {
        if (terms.len != 1) return app.fail("give one search term", .{});
        const ctx = try app.context();
        for (try app.candidates(ctx, true)) |c| {
            if (std.mem.indexOf(u8, c.entry.name, terms[0]) == null and
                std.ascii.findIgnoreCase(c.entry.description, terms[0]) == null) continue;
            try app.say("{s} {s}  {s}", .{ c.entry.name, c.entry.version, c.entry.description });
        }
    }

    // -- system ---------------------------------------------------------------

    fn requireSystem(app: *App) !deploy.System {
        const current = app.runningDeployment() orelse
            return app.fail("this command only applies to a running joe Linux system", .{});
        return app.openSystem(current);
    }

    fn cmdStatus(app: *App) !void {
        const current = app.runningDeployment() orelse {
            const ctx = try app.context();
            return app.say("{d} packages installed in {s} (not a deployment-managed system).", .{ ctx.installed.len, app.opts.root });
        };
        var sys = try app.openSystem(current);
        const view = try sys.overview();
        try app.say("Running deployment {d}.", .{current});
        for (view.deployments) |d| {
            if (d.next_boot and !d.running) try app.say("Deployment {d} will start on the next boot.", .{d.id});
        }
        if (view.staged) |staged| {
            try app.say("An upgrade is ready ({s}); it will be applied at shutdown.", .{staged.summary});
        }
        if (view.last_finalize) |last| {
            if (!last.ok) try app.say("The last upgrade could not be applied: {s}", .{last.message});
        }
        try app.say("", .{});
        try app.printDeployments(view);
    }

    fn printDeployments(app: *App, view: deploy.System.Overview) !void {
        for (view.deployments) |d| {
            const health: []const u8 = if (d.health) |h| switch (h) {
                .good => "good",
                .trial => "untested",
                .bad => "failed",
            } else "no boot entry";
            const mark: []const u8 = if (d.running) "*" else if (d.next_boot) ">" else " ";
            const pinned: []const u8 = if (d.record != null and d.record.?.pinned) "  pinned" else "";
            const reason: []const u8 = if (d.record) |r| r.reason else "";
            try app.say("{s} {d:>4}  {s:<13}{s}  {s}", .{ mark, d.id, health, pinned, reason });
        }
        try app.say("\n* running   > starts on next boot", .{});
    }

    fn cmdRollback(app: *App) !void {
        var lock_file = try app.lock();
        defer lock_file.close(app.io);
        var sys = try app.requireSystem();
        const target = sys.rollback() catch |e| {
            if (sys.diag.message.len > 0) return app.fail("{s}", .{sys.diag.message});
            return app.fail("cannot roll back: {t}", .{e});
        };
        try app.say("Deployment {d} will start on the next boot, and on every boot after it.", .{target});
        try app.say("Reboot to return to it.", .{});
    }

    fn cmdDeployments(app: *App, args: []const []const u8) !void {
        var sys = try app.requireSystem();
        if (args.len == 0 or std.mem.eql(u8, args[0], "list")) return app.printDeployments(try sys.overview());
        var lock_file = try app.lock();
        defer lock_file.close(app.io);
        if (std.mem.eql(u8, args[0], "gc")) {
            const removed = try sys.collectGarbage(deploy.default_keep);
            return app.say("Removed {d} deployment(s).", .{removed.len});
        }
        const pin = std.mem.eql(u8, args[0], "pin");
        if (!pin and !std.mem.eql(u8, args[0], "unpin")) return app.fail("unknown deployments command '{s}'", .{args[0]});
        if (args.len != 2) return app.fail("give one deployment id", .{});
        const id = std.fmt.parseInt(u32, args[1], 10) catch return app.fail("'{s}' is not a deployment id", .{args[1]});
        sys.setPinned(id, pin) catch |e| {
            if (sys.diag.message.len > 0) return app.fail("{s}", .{sys.diag.message});
            return e;
        };
        try app.say("Deployment {d} {s}.", .{ id, if (pin) "pinned" else "unpinned" });
    }

    /// Run by dave-finalize.service as the system shuts down.
    fn cmdFinalize(app: *App) !void {
        const current = app.runningDeployment() orelse return;
        var lock_file = try app.lock();
        defer lock_file.close(app.io);
        var sys = try app.openSystem(current);
        const outcome = (try sys.finalize()) orelse return;
        if (outcome.ok) {
            try app.say("Upgrade applied as deployment {d}; it will start on the next boot.", .{outcome.deployment.?});
        } else {
            // Not an error exit: the shutdown must proceed and the old system
            // boots unchanged. `dave status` reports this afterwards.
            app.err.print("dave: the upgrade could not be applied: {s}\n", .{outcome.message}) catch {};
        }
    }

    /// Run by dave-boot-check.service on the first boots of a new deployment.
    /// Exiting non-zero makes systemd reboot, which counts as a failed attempt.
    fn cmdBootCheck(app: *App) !void {
        const current = app.runningDeployment() orelse return;
        for ([_][]const u8{ "/var", esp_path }) |point| {
            if (app.findMount(point) == null) return app.fail("boot check failed: {s} is not mounted", .{point});
        }
        const root = try app.openDir("/");
        _ = db.load(app.arena, app.io, root) catch |e| return app.fail("boot check failed: the package database is unreadable: {t}", .{e});

        // Site-specific checks: every executable here must succeed.
        if (root.openDir(app.io, boot_check_hooks, .{ .iterate = true })) |hooks| {
            var it = hooks.iterate();
            while (try it.next(app.io)) |e| {
                const path = try std.fmt.allocPrint(app.arena, "/" ++ boot_check_hooks ++ "/{s}", .{e.name});
                var child = std.process.spawn(app.io, .{ .argv = &.{path}, .stdin = .ignore }) catch |err|
                    return app.fail("boot check failed: cannot run {s}: {t}", .{ path, err });
                const term = try child.wait(app.io);
                if (!term.success()) return app.fail("boot check failed: {s} reported a problem", .{path});
            }
        } else |_| {}

        try app.say("Deployment {d} passed its boot check.", .{current});
        // Housekeeping is best effort; it must never fail a healthy boot.
        var lock_file = app.lock() catch return;
        defer lock_file.close(app.io);
        var sys = app.openSystem(current) catch return;
        _ = sys.collectGarbage(deploy.default_keep) catch {};
    }

    // -- building -------------------------------------------------------------

    fn absolute(app: *App, path: []const u8) ![]const u8 {
        if (std.fs.path.isAbsolute(path)) return path;
        const cwd = try Io.Dir.cwd().realPathFileAlloc(app.io, ".", app.arena);
        return std.fs.path.join(app.arena, &.{ cwd, path });
    }

    fn cmdBuild(app: *App, args: []const []const u8) !void {
        if (args.len != 1) return app.fail("give one recipe directory", .{});
        const recipe_dir = try app.absolute(args[0]);
        const driver = if (app.opts.driver) |d|
            try app.absolute(d)
        else
            try std.fs.path.join(app.arena, &.{ std.fs.path.dirname(recipe_dir) orelse "/", ".build", "driver.sh" });
        var diag: builder.Diagnostic = .{};
        const file = builder.build(app.arena, app.io, .{
            .recipe_dir = recipe_dir,
            .build_root = try app.absolute(app.opts.buildroot orelse return app.fail("--buildroot is required", .{})),
            .sources_dir = try app.absolute(app.opts.sources orelse return app.fail("--sources is required", .{})),
            .work_dir = try app.absolute(app.opts.work orelse return app.fail("--work is required", .{})),
            .out_dir = try app.absolute(app.opts.out orelse return app.fail("--out is required", .{})),
            .driver = driver,
            .jobs = std.Thread.getCpuCount() catch 1,
            .keep_work = app.opts.keep_work,
        }, &diag) catch |e| {
            if (diag.message.len > 0) return app.fail("{s}", .{diag.message});
            return app.fail("cannot build {s}: {t}", .{ args[0], e });
        };
        try app.say("{s}", .{file});
    }

    fn cmdPack(app: *App, args: []const []const u8) !void {
        if (args.len != 1) return app.fail("give the directory to pack", .{});
        const name = app.opts.name orelse return app.fail("--name is required", .{});
        const pkg_version = app.opts.pkg_version orelse return app.fail("--version is required", .{});
        const out_path = app.opts.out orelse return app.fail("--out is required", .{});
        if (!manifest.validName(name)) return app.fail("'{s}' is not a valid package name", .{name});
        _ = version.Version.parse(pkg_version) catch return app.fail("'{s}' is not a valid version", .{pkg_version});
        if (std.mem.lastIndexOf(u8, pkg_version, "-r") == null) return app.fail("the version needs a release, e.g. {s}-r1", .{pkg_version});
        for (app.opts.depends.items) |d| {
            _ = range.Range.parse(app.arena, manifest.splitDependency(d).constraint) catch return app.fail("cannot understand dependency '{s}'", .{d});
        }
        const src = try app.openDir(args[0]);
        Io.Dir.cwd().createDirPath(app.io, out_path) catch {};
        const out_dir = try app.openDir(out_path);
        const file = archive.pack(app.arena, app.io, .{
            .meta = .{
                .name = name,
                .version = pkg_version,
                .description = app.opts.description,
                .license = app.opts.license,
                .depends = app.opts.depends.items,
                .conflicts = app.opts.conflicts.items,
            },
            .src = src,
            .out_dir = out_dir,
        }) catch |e| return app.fail("cannot pack {s}: {t}", .{ args[0], e });
        try app.say("{s}/{s}", .{ out_path, file });
    }

    fn cmdRepo(app: *App, args: []const []const u8) !void {
        if (args.len != 2 or !std.mem.eql(u8, args[0], "index")) return app.fail("usage: dave repo index <dir> [--key FILE]", .{});
        const dir = try app.openDir(args[1]);
        const secret: ?[]const u8 = if (app.opts.key) |path|
            app.readAbsolute(path) orelse return app.fail("cannot read key {s}", .{path})
        else
            null;
        const count = repo.writeIndex(app.gpa, app.arena, app.io, dir, secret) catch |e| return app.fail("cannot index {s}: {t}", .{ args[1], e });
        try app.say("Indexed {d} package(s){s}.", .{ count, if (secret == null) " (unsigned)" else "" });
    }

    fn cmdKey(app: *App, args: []const []const u8) !void {
        if (args.len != 2 or !std.mem.eql(u8, args[0], "generate")) return app.fail("usage: dave key generate <basename>", .{});
        const key = repo.generateKey(app.io);
        const secret_path = try std.fmt.allocPrint(app.arena, "{s}.key", .{args[1]});
        const public_path = try std.fmt.allocPrint(app.arena, "{s}.pub", .{args[1]});
        const cwd = Io.Dir.cwd();
        cwd.writeFile(app.io, .{ .sub_path = secret_path, .data = &key.secret_hex, .flags = .{ .exclusive = true, .permissions = .fromMode(0o600) } }) catch |e|
            return app.fail("cannot write {s}: {t}", .{ secret_path, e });
        cwd.writeFile(app.io, .{ .sub_path = public_path, .data = &key.public_hex }) catch |e|
            return app.fail("cannot write {s}: {t}", .{ public_path, e });
        try app.say("Wrote {s} (keep secret) and {s} (install into {s}/).", .{ secret_path, public_path, repo.keys_path });
    }

    /// `dave --chroot-exec <dir> <program> [args...]`: used to run triggers
    /// inside a root other than the running one.
    fn chrootExec(app: *App, args: []const []const u8) !void {
        if (args.len < 2) return app.fail("--chroot-exec needs a directory and a program", .{});
        const dir = try app.arena.dupeSentinel(u8, args[0], 0);
        if (linux.errno(linux.chroot(dir)) != .SUCCESS) return app.fail("cannot chroot to {s}", .{args[0]});
        if (linux.errno(linux.chdir("/")) != .SUCCESS) return app.fail("cannot enter {s}", .{args[0]});
        const e = std.process.replace(app.io, .{ .argv = args[1..] });
        return app.fail("cannot run {s} in {s}: {t}", .{ args[1], args[0], e });
    }
};

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const raw = try init.minimal.args.toSlice(arena);
    const args = try arena.alloc([]const u8, raw.len -| 1);
    for (args, raw[@min(raw.len, 1)..]) |*dst, src| dst.* = src;

    var out_buf: [4096]u8 = undefined;
    var err_buf: [1024]u8 = undefined;
    var out_writer = Io.File.stdout().writer(init.io, &out_buf);
    var err_writer = Io.File.stderr().writer(init.io, &err_buf);
    var app: App = .{
        .gpa = init.gpa,
        .arena = arena,
        .io = init.io,
        .out = &out_writer.interface,
        .err = &err_writer.interface,
    };
    var code: u8 = 0;
    app.run(args) catch |e| {
        code = 1;
        if (e != error.Reported) err_writer.interface.print("dave: unexpected failure: {t}\n", .{e}) catch {};
    };
    out_writer.interface.flush() catch {};
    err_writer.interface.flush() catch {};
    std.process.exit(code);
}

test {
    std.testing.refAllDecls(@This());
}

test "the mount table can be read and the root found in it" {
    var arena_state: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena_state.deinit();
    var sink: Io.Writer.Allocating = .init(arena_state.allocator());
    var app: App = .{
        .gpa = std.testing.allocator,
        .arena = arena_state.allocator(),
        .io = std.testing.io,
        .out = &sink.writer,
        .err = &sink.writer,
    };
    try std.testing.expect(app.readAbsolute("/proc/self/mountinfo") != null);
    const root = app.findMount("/") orelse return error.RootMountNotFound;
    try std.testing.expect(root.fstype.len > 0);
    try std.testing.expect(app.findMount("/definitely/not/a/mount/point") == null);
}
