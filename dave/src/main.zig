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
pub const seal = @import("seal.zig");
pub const provision = @import("provision.zig");
pub const image = @import("image.zig");
pub const cpio = @import("cpio.zig");
pub const iso = @import("iso.zig");
pub const command = @import("command.zig");
pub const install_system = @import("install_system.zig");

const dave_version = "0.2.2";
const top_mount = "/run/dave/top";
const lock_path = "/run/dave/lock";
/// What `dave status` shows, written by root for everyone (deploy.Published).
const status_path = "/run/dave/status.zon";
const esp_path = "/efi";
const system_cache = "/var/cache/dave";
const boot_check_hooks = "etc/dave/boot-check.d";
const sealed_marker = "usr/lib/dave/sealed";

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
    \\  repo audit <dir>                             Audit package seals and declarations
    \\  key generate <basename>                      Create a repository signing key pair
    \\  key generate-code <basename>                 Create a code-signing key pair
    \\  seal                                         Seal installed files that are not yet sealed
    \\
    \\Images and installation
    \\  image build <spec> --out FILE              Build a disk image or live medium from a
    \\      [--test] [--repo NAME,DIR,URL,KEY]...  specification (image/*.zon); DIR is read while
    \\      [--with PACKAGE]... [--tree DIR]        building, URL is what the image will use
    \\  install-system --list [--json]             The disks joe Linux could be installed on
    \\  install-system --disk DISK [--json]        Erase DISK and install what the live medium
    \\                                             holds (joe/install.zon) onto it
    \\
    \\Options
    \\  --root DIR       Operate on the system installed at DIR instead of /
    \\  --cache DIR      Where downloaded indexes and packages are kept
    \\  --dry-run        Show what would be done and stop
    \\  --no-triggers    Do not run package triggers
    \\  --overwrite      Replace files that exist but belong to no package
    \\  --code-key FILE  Seal the files of the package being built with this key
    \\  --allow OP        An operation the package declares (pack), or the
    \\                    declaration for recipes that make none (build); without
    \\                    it, programs nothing declares are sealed `undeclared`
    \\  --test           (image) Add joe-test-console: root logged in on the serial
    \\                   console. For automated tests only
    \\  --with PACKAGE   (image) Install PACKAGE as well as the spec's packages
    \\  --tree DIR       (image) Start from DIR instead of the spec's tree
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
    test_image: bool = false,
    tree: ?[]const u8 = null,
    json: bool = false,
    list: bool = false,
    disk: ?[]const u8 = null,
    from: ?[]const u8 = null,
    repos: std.ArrayList([]const u8) = .empty,
    with: std.ArrayList([]const u8) = .empty,
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
    code_key: ?[]const u8 = null,
    allow: std.ArrayList([]const u8) = .empty,
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
    /// The arguments dave was started with, for re-executing itself.
    argv: []const []const u8 = &.{},
    /// The environment of programs dave runs; null leaves them dave's own.
    environ: ?*std.process.Environ.Map = null,
    /// With --json, where events go (standard output); `out` then carries
    /// what is said for people, on standard error.
    events: ?*Io.Writer = null,
    /// The last failure, for the error event.
    last_error: []const u8 = "",
    /// Passed to transactions, for progress events.
    progress: ?txn.Progress = null,
    /// Set once the running system's deployments have been opened, so that
    /// what `dave status` shows is published again before dave exits.
    opened_system: bool = false,

    // -- reporting ------------------------------------------------------------

    /// Prints a message for the user and returns the error that ends the command.
    fn fail(app: *App, comptime fmt: []const u8, args: anytype) Failure {
        app.last_error = std.fmt.allocPrint(app.arena, fmt, args) catch "out of memory";
        app.err.print("dave: {s}\n", .{app.last_error}) catch {};
        app.err.flush() catch {};
        return error.Reported;
    }

    /// One JSON object on a line of its own, for a program watching dave
    /// (the installer). A reader that has gone away must not stop the work
    /// it was watching, so writing errors are ignored.
    fn event(app: *App, kind: []const u8, message: []const u8, fraction: ?f64) void {
        const w = app.events orelse return;
        std.json.Stringify.value(.{ .event = kind, .message = message, .fraction = fraction }, .{ .emit_null_optional_fields = false }, w) catch return;
        w.writeByte('\n') catch return;
        w.flush() catch return;
    }

    /// A step of a long operation: for people, and as an event.
    fn step(app: *App, fraction: f64, comptime fmt: []const u8, args: anytype) void {
        const message = std.fmt.allocPrint(app.arena, fmt, args) catch return;
        app.say("==> {s}", .{message}) catch {};
        app.event("step", message, fraction);
    }

    fn say(app: *App, comptime fmt: []const u8, args: anytype) !void {
        try app.out.print(fmt ++ "\n", args);
        // Long operations (an image build) report as they go.
        try app.out.flush();
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
            } else if (std.mem.eql(u8, arg, "--test")) {
                app.opts.test_image = true;
            } else if (std.mem.eql(u8, arg, "--json")) {
                app.opts.json = true;
            } else if (std.mem.eql(u8, arg, "--list")) {
                app.opts.list = true;
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
                } else if (std.mem.eql(u8, arg, "--code-key")) {
                    app.opts.code_key = value;
                } else if (std.mem.eql(u8, arg, "--allow")) {
                    try app.opts.allow.append(app.arena, value);
                } else if (std.mem.eql(u8, arg, "--depends")) {
                    try app.opts.depends.append(app.arena, value);
                } else if (std.mem.eql(u8, arg, "--conflicts")) {
                    try app.opts.conflicts.append(app.arena, value);
                } else if (std.mem.eql(u8, arg, "--repo")) {
                    try app.opts.repos.append(app.arena, value);
                } else if (std.mem.eql(u8, arg, "--with")) {
                    try app.opts.with.append(app.arena, value);
                } else if (std.mem.eql(u8, arg, "--tree")) {
                    app.opts.tree = value;
                } else if (std.mem.eql(u8, arg, "--disk")) {
                    app.opts.disk = value;
                } else if (std.mem.eql(u8, arg, "--from")) {
                    app.opts.from = value;
                } else {
                    return app.fail("unknown option {s}", .{arg});
                }
            }
        }
    }

    // -- dispatch -------------------------------------------------------------

    fn run(app: *App, args: []const []const u8) !void {
        if (args.len >= 1 and std.mem.eql(u8, args[0], triggers.chroot_command)) return app.chrootExec(args[1..]);
        app.argv = args;
        try app.parseArgs(args);
        const pos = app.opts.positional.items;
        if (pos.len == 0) {
            try app.out.writeAll(usage);
            return;
        }
        const cmd = pos[0];
        const rest = pos[1..];
        // Whatever the command did, and whether or not it succeeded, users
        // without root then see the system as it now is.
        defer if (app.opened_system) app.publishStatus();
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
        if (std.mem.eql(u8, cmd, "seal")) return app.cmdSeal();
        if (std.mem.eql(u8, cmd, "image")) return app.cmdImage(rest);
        if (std.mem.eql(u8, cmd, "install-system")) return app.cmdInstallSystem(rest);
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
        // Every deployment is under it, with the set-uid programs of each:
        // they must not run from here. openSystem also closes it to users.
        const rc = linux.mount(source, top_mount, "btrfs", linux.MS.NOSUID | linux.MS.NODEV, @intFromPtr(@as([*:0]const u8, "subvolid=5")));
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
        const top = try app.openDir(top_mount);
        // Only root may enter the top level, through this mount or any other:
        // old deployments keep the set-uid programs they were made with.
        top.setPermissions(app.io, .fromMode(0o700)) catch |e|
            return app.fail("cannot close {s} to other users: {t}", .{ top_mount, e });
        const sys: deploy.System = .{
            .gpa = app.gpa,
            .arena = app.arena,
            .io = app.io,
            .top = top,
            .top_path = top_mount,
            .esp = try app.openDir(esp_path),
            .root = try app.openDir("/"),
            .cache = try app.openDir(system_cache),
            .current = current,
            .run_triggers = !app.opts.no_triggers,
        };
        app.opened_system = true;
        return sys;
    }

    /// Writes what `dave status` shows to `status_path`, readable by everyone.
    /// Best effort and silent: the command has already succeeded or failed,
    /// and must not be reported otherwise because of this.
    fn publishStatus(app: *App) void {
        if (linux.geteuid() != 0) return;
        const current = app.runningDeployment() orelse return;
        var sys: deploy.System = .{
            .gpa = app.gpa,
            .arena = app.arena,
            .io = app.io,
            .top = Io.Dir.cwd().openDir(app.io, top_mount, .{ .iterate = true }) catch return,
            .top_path = top_mount,
            .esp = Io.Dir.cwd().openDir(app.io, esp_path, .{ .iterate = true }) catch return,
            .root = Io.Dir.cwd().openDir(app.io, "/", .{ .iterate = true }) catch return,
            .cache = Io.Dir.cwd().openDir(app.io, system_cache, .{ .iterate = true }) catch return,
            .current = current,
        };
        defer for ([_]Io.Dir{ sys.top, sys.esp, sys.root, sys.cache }) |d| d.close(app.io);
        const text = deploy.Published.of(current, sys.overview() catch return).serialize(app.arena) catch return;
        var dir = Io.Dir.cwd().openDir(app.io, std.fs.path.dirname(status_path).?, .{}) catch return;
        defer dir.close(app.io);
        db.writeAtomicWith(app.arena, app.io, dir, std.fs.path.basename(status_path), text, .fromMode(0o644)) catch return;
    }

    /// The deployments as root last published them, if that was during this
    /// boot of this deployment.
    fn publishedView(app: *App, current: u32) ?deploy.System.Overview {
        const text = app.readAbsolute(status_path) orelse return null;
        const published = deploy.Published.parse(app.arena, text) catch return null;
        if (published.running != current) return null;
        return published.overview();
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
        for (ctx.config.repos) |r| {
            repo.refreshRepo(app.gpa, app.arena, app.io, r, ctx.trusted, ctx.cache) catch |e| switch (e) {
                error.BadSignature => return app.fail("a repository index is not signed by a trusted key; nothing was changed", .{}),
                error.TlsInitializationFailed => return app.fail(tls_failed, .{r.url}),
                error.CertificateBundleLoadFailure => return app.fail(no_certificates, .{}),
                else => return app.fail("cannot refresh repository {s} ({s}): {t}", .{ r.name, r.url, e }),
            };
        }
        return repo.loadCached(app.arena, app.io, ctx.config, ctx.trusted, ctx.cache) catch |e|
            app.fail("the cached repository index is unusable: {t}", .{e});
    }

    // The HTTP client reports every failed TLS handshake as one error; by far
    // the most common cause is a certificate this system does not accept.
    const tls_failed = "cannot connect securely to {s} (is its certificate valid, and trusted by this system?); nothing was changed";
    const no_certificates = "cannot read this system's trusted certificates (/etc/pki/tls/certs/ca-bundle.crt); nothing was changed";

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
                error.TlsInitializationFailed => return app.fail(tls_failed, .{u.candidate.repo_url}),
                error.CertificateBundleLoadFailure => return app.fail(no_certificates, .{}),
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
            .progress = app.progress,
        }, &diag) catch |e| {
            if (diag.message.len > 0) return app.fail("{s}", .{diag.message});
            return app.fail("the transaction failed: {t}", .{e});
        };
        for (result.notes) |n| try app.say("note: {s}", .{n});
        if (result.unsealed > 0 and app.runningDeployment() != null)
            try app.say("note: {d} file(s) could not be sealed here; run 'dave seal'", .{result.unsealed});
        if (app.opts.no_triggers) return;
        const wanted = try triggers.matching(app.arena, try triggers.load(app.arena, app.io, ctx.root), result.changed_paths);
        const live = std.mem.eql(u8, app.opts.root, "/");
        triggers.run(app.arena, app.io, wanted, .{
            .root = ctx.root,
            .chroot_path = if (live) null else try Io.Dir.cwd().realPathFileAlloc(app.io, app.opts.root, app.arena),
            .self_exe = "/proc/self/exe",
            .environ_map = app.environ,
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
        // Only root can refresh the index; anyone can search the one fetched last.
        const root = linux.geteuid() == 0;
        const found = try app.candidates(ctx, root);
        if (!root and found.len == 0)
            return app.fail("no repository index has been fetched yet; 'sudo dave search {s}' fetches it", .{terms[0]});
        for (found) |c| {
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
        if (linux.geteuid() != 0) {
            const view = app.publishedView(current) orelse {
                try app.say("Running deployment {d}.", .{current});
                return app.say("Until dave-status.service has run at boot, only root can see the other deployments " ++
                    "and any pending upgrade; 'sudo dave status' shows them.", .{});
            };
            return app.printStatus(current, view);
        }
        var sys = try app.openSystem(current);
        try app.printStatus(current, try sys.overview());
    }

    fn printStatus(app: *App, current: u32, view: deploy.System.Overview) !void {
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
        const missing = sys.accountsMissingIn(target) catch &.{};
        if (missing.len > 0) {
            const names = try std.mem.join(app.arena, ", ", missing);
            try app.say("Warning: deployment {d} was made before these accounts were created: {s}.", .{ target, names });
            try app.say("Their files under /home are kept, but they cannot log in there until the accounts are created again.", .{});
        }
        try app.say("Reboot to return to it.", .{});
    }

    fn cmdDeployments(app: *App, args: []const []const u8) !void {
        if (args.len == 0 or std.mem.eql(u8, args[0], "list")) {
            const current = app.runningDeployment() orelse
                return app.fail("this command only applies to a running joe Linux system", .{});
            if (linux.geteuid() != 0)
                return app.printDeployments(app.publishedView(current) orelse
                    return app.fail("until dave-status.service has run at boot, only root can list the deployments; " ++
                        "'sudo dave deployments' lists them", .{}));
            var sys = try app.openSystem(current);
            return app.printDeployments(try sys.overview());
        }
        var sys = try app.requireSystem();
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
        // Left by an upgrade made with dave 0.2.1 or earlier (deploy.zig).
        _ = sys.removeHiddenSubvolumes() catch {};
        _ = sys.collectGarbage(deploy.default_keep) catch {};
    }

    // -- building -------------------------------------------------------------

    fn absolute(app: *App, path: []const u8) ![]const u8 {
        if (std.fs.path.isAbsolute(path)) return path;
        const cwd = try Io.Dir.cwd().realPathFileAlloc(app.io, ".", app.arena);
        return std.fs.path.join(app.arena, &.{ cwd, path });
    }

    fn codeKey(app: *App) !?seal.SigningKey {
        const path = app.opts.code_key orelse return null;
        const text = app.readAbsolute(path) orelse return app.fail("cannot read code-signing key {s}", .{path});
        return seal.SigningKey.parse(text) catch app.fail("{s} is not a code-signing key", .{path});
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
            .code_key = try app.codeKey(),
            .default_allow = app.opts.allow.items,
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
                .operations = if (app.opts.allow.items.len > 0) &.{.{ .allow = app.opts.allow.items }} else &.{},
            },
            .src = src,
            .out_dir = out_dir,
            .code_key = try app.codeKey(),
        }) catch |e| return app.fail("cannot pack {s}: {t}", .{ args[0], e });
        try app.say("{s}/{s}", .{ out_path, file });
    }

    fn cmdRepo(app: *App, args: []const []const u8) !void {
        if (args.len != 2 or (!std.mem.eql(u8, args[0], "index") and !std.mem.eql(u8, args[0], "audit")))
            return app.fail("usage: dave repo index|audit <dir>", .{});
        const dir = try app.openDir(args[1]);
        if (std.mem.eql(u8, args[0], "audit")) {
            const problems = repo.audit(app.gpa, app.arena, app.io, dir, app.out) catch |e|
                return app.fail("cannot audit {s}: {t}", .{ args[1], e });
            if (problems > 0) {
                try app.say("{d} security problem(s) found.", .{problems});
                return error.Reported;
            }
            try app.say("No seal or declaration problems found.", .{});
            return;
        }
        const secret: ?[]const u8 = if (app.opts.key) |path|
            app.readAbsolute(path) orelse return app.fail("cannot read key {s}", .{path})
        else
            null;
        const count = repo.writeIndex(app.gpa, app.arena, app.io, dir, secret) catch |e| return app.fail("cannot index {s}: {t}", .{ args[1], e });
        try app.say("Indexed {d} package(s){s}.", .{ count, if (secret == null) " (unsigned)" else "" });
    }

    fn cmdKey(app: *App, args: []const []const u8) !void {
        if (args.len != 2) return app.fail("usage: dave key generate|generate-code <basename>", .{});
        const code = std.mem.eql(u8, args[0], "generate-code");
        if (!code and !std.mem.eql(u8, args[0], "generate")) return app.fail("usage: dave key generate|generate-code <basename>", .{});
        const secret_path = try std.fmt.allocPrint(app.arena, "{s}.key", .{args[1]});
        const public_path = try std.fmt.allocPrint(app.arena, "{s}.pub", .{args[1]});
        var secret: []const u8 = undefined;
        var public: []const u8 = undefined;
        if (code) {
            const key = seal.generateKey(app.io);
            secret = try app.arena.dupe(u8, &key.secret_hex);
            public = try app.arena.dupe(u8, &key.public_hex);
        } else {
            const key = repo.generateKey(app.io);
            secret = try app.arena.dupe(u8, &key.secret_hex);
            public = try app.arena.dupe(u8, &key.public_hex);
        }
        const cwd = Io.Dir.cwd();
        cwd.writeFile(app.io, .{ .sub_path = secret_path, .data = secret, .flags = .{ .exclusive = true, .permissions = .fromMode(0o600) } }) catch |e|
            return app.fail("cannot write {s}: {t}", .{ secret_path, e });
        cwd.writeFile(app.io, .{ .sub_path = public_path, .data = public }) catch |e|
            return app.fail("cannot write {s}: {t}", .{ public_path, e });
        if (code) {
            try app.say("Wrote {s} (keep secret) and {s} (built into the kernel).", .{ secret_path, public_path });
        } else {
            try app.say("Wrote {s} (keep secret) and {s} (install into {s}/).", .{ secret_path, public_path, repo.keys_path });
        }
    }

    /// Seals every installed file whose manifest carries a seal and which is
    /// not sealed yet. An image assembled without privileges cannot seal its
    /// files, so this runs on its first boot; afterwards it finds nothing to do.
    fn cmdSeal(app: *App) !void {
        const root = try app.openDir(app.opts.root);
        // Invalidate an older marker before anything that can fail. Otherwise
        // dave-seal.service would suppress all later attempts after a bad pass.
        root.deleteFile(app.io, sealed_marker) catch |e| switch (e) {
            error.FileNotFound => {},
            else => return app.fail("cannot invalidate the old sealed marker: {t}", .{e}),
        };
        const installed = db.load(app.arena, app.io, root) catch |e| return app.fail("the package database is unreadable: {t}", .{e});
        var done: usize = 0;
        var already: usize = 0;
        var invalid: usize = 0;
        var modified: usize = 0;
        var impossible: usize = 0;
        for (installed) |m| {
            for (m.files) |f| {
                if (f.kind != .file or f.config) continue;
                const signature_text = f.seal orelse {
                    invalid += 1;
                    continue;
                };
                const verity_text = f.verity orelse {
                    invalid += 1;
                    continue;
                };
                const signature = seal.parseSignature(signature_text) orelse {
                    invalid += 1;
                    continue;
                };
                const verity = seal.parseDigest(verity_text) orelse {
                    invalid += 1;
                    continue;
                };
                const ops = seal.operationsText(app.arena, m.operations, f.path) catch {
                    invalid += 1;
                    continue;
                };
                const value = try seal.attribute(app.arena, ops, signature);
                if (seal.isApplied(app.io, root, f.path, verity, value, seal.xattr_name)) {
                    already += 1;
                    continue;
                }
                // Sealing fixes the contents for good, so only seal what the
                // package actually shipped. Missing and unreadable files are
                // failures too, never a reason to mark the root complete.
                const actual = seal.verityDigestOfFile(app.io, root, f.path) catch {
                    invalid += 1;
                    continue;
                };
                if (!std.mem.eql(u8, &actual, &verity)) {
                    modified += 1;
                    continue;
                }
                switch (seal.apply(app.io, root, f.path, value, seal.xattr_name) catch |e|
                    return app.fail("cannot seal {s}: {t}", .{ f.path, e })) {
                    .sealed => done += 1,
                    .not_possible => impossible += 1,
                }
            }
        }
        try app.say("Sealed {d} file(s); {d} were already sealed.", .{ done, already });
        if (invalid > 0) return app.fail("{d} file(s) have missing, malformed, or unreadable seals", .{invalid});
        if (modified > 0) return app.fail("{d} file(s) differ from what their package shipped and were left unsealed", .{modified});
        if (impossible > 0) return app.fail("{d} file(s) could not be sealed: the file system lacks fs-verity or this is not root", .{impossible});
        // Tells dave-seal.service that this root needs no further pass.
        root.writeFile(app.io, .{ .sub_path = sealed_marker, .data = "" }) catch |e|
            return app.fail("cannot mark this root as sealed: {t}", .{e});
    }

    // -- images ---------------------------------------------------------------

    fn cmdImage(app: *App, args: []const []const u8) !void {
        if (args.len != 2 or !std.mem.eql(u8, args[0], "build"))
            return app.fail("usage: dave image build <spec> --out FILE [--test] [--repo NAME,DIR,URL,KEY]... [--with PACKAGE]... [--tree DIR]", .{});
        const out = app.opts.out orelse return app.fail("--out is required", .{});
        // Every file in the image must be owned by root. Without privileges,
        // the build runs where this user is root: a user namespace.
        if (linux.getuid() != 0) return app.reenterAsRoot();

        const spec_path = try app.absolute(args[1]);
        const text = app.readAbsolute(spec_path) orelse return app.fail("cannot read {s}", .{args[1]});
        var diag: image.Diagnostic = .{};
        const spec = image.parseSpec(app.arena, text, args[1], &diag) catch |e| switch (e) {
            error.InvalidSpec => return app.fail("{s}", .{diag.message}),
            else => return e,
        };
        var repos: std.ArrayList(image.RepoArg) = .empty;
        for (app.opts.repos.items) |r| {
            try repos.append(app.arena, image.parseRepoArg(r) catch
                return app.fail("--repo takes NAME,DIR,URL,KEY, not {s}", .{r}));
        }
        const out_path = try app.absolute(out);
        var b: image.Builder = .{
            .arena = app.arena,
            .io = app.io,
            .spec = spec,
            .spec_dir = std.fs.path.dirname(spec_path) orelse "/",
            .out = out_path,
            .work = try std.fmt.allocPrint(app.arena, "{s}.work", .{out_path}),
            .repos = repos.items,
            .test_image = app.opts.test_image,
            .tree_override = if (app.opts.tree) |t| try app.absolute(t) else null,
            .extra_packages = app.opts.with.items,
        };
        defer b.cleanup();
        const packages = try b.packages();
        if (packages.len > 0 and repos.items.len == 0) return app.fail("{s} installs packages: name where they come from with --repo", .{args[1]});

        try app.say("==> {s}: the root", .{spec.name});
        b.prepareTree() catch |e| return app.imageFailed(&b, e);
        if (packages.len > 0) {
            if (app.opts.test_image) {
                if (app.environ) |env| try env.put("CREDENTIALS_DIRECTORY", image.Builder.credentials_path);
            }
            app.opts.root = try b.treePath();
            app.opts.cache = null;
            try app.cmdChange(.install, packages);
        }
        b.finishTree() catch |e| return app.imageFailed(&b, e);
        switch (spec.format) {
            .disk => {
                try app.say("==> {s}: disk image", .{spec.name});
                b.buildDisk() catch |e| return app.imageFailed(&b, e);
            },
            .iso => {
                try app.say("==> {s}: the initramfs", .{spec.name});
                b.prepareInitrd() catch |e| return app.imageFailed(&b, e);
                app.opts.root = try b.initrdPath();
                app.opts.cache = null;
                try app.cmdChange(.install, spec.iso.?.initrd.packages);
                b.finishInitrd() catch |e| return app.imageFailed(&b, e);
                try app.say("==> {s}: what the installer installs", .{spec.name});
                b.preparePayloadRoot() catch |e| return app.imageFailed(&b, e);
                const files = try app.payloadFiles(try b.payloadRootPath(), try b.payload());
                try app.say("==> {s}: the medium, with {d} packages for the installer", .{ spec.name, files.len });
                b.buildIso(files) catch |e| return app.imageFailed(&b, e);
            },
        }
        try app.say("image ready: {s}", .{out});
    }

    /// The package files installing `names` into an empty root takes: the
    /// same solve the installer will make from the medium.
    fn payloadFiles(app: *App, root_path: []const u8, names: []const []const u8) ![]image.MediumFile {
        app.opts.root = root_path;
        app.opts.cache = null;
        const ctx = try app.context();
        var world: std.ArrayList(db.WorldEntry) = .empty;
        for (names) |n| try world.append(app.arena, .{ .name = n });
        const solution = try app.solve(.{
            .world = world.items,
            .installed = ctx.installed,
            .candidates = try app.candidates(ctx, true),
            .mode = .keep_installed,
        });
        const files = try app.arena.alloc(image.MediumFile, solution.install.len);
        for (solution.install, files) |u, *f| f.* = .{ .repo_dir = u.candidate.repo_url, .filename = u.candidate.entry.filename };
        return files;
    }

    fn imageFailed(app: *App, b: *image.Builder, e: anyerror) Failure {
        if (b.diag.message.len > 0) return app.fail("{s}", .{b.diag.message});
        return app.fail("the image could not be built: {t}", .{e});
    }

    /// Runs this same command again as root of a new user namespace, through
    /// unshare(1): a process with more than one thread (and the I/O
    /// implementation may have started some) cannot enter one itself.
    fn reenterAsRoot(app: *App) Failure {
        const exe = std.process.executablePathAlloc(app.io, app.arena) catch |e|
            return app.fail("cannot find the dave executable: {t}", .{e});
        var argv: std.ArrayList([]const u8) = .empty;
        argv.appendSlice(app.arena, &.{ "unshare", "--map-root-user", exe }) catch return app.fail("out of memory", .{});
        argv.appendSlice(app.arena, app.argv) catch return app.fail("out of memory", .{});
        app.out.flush() catch {};
        app.err.flush() catch {};
        const e = std.process.replace(app.io, .{ .argv = argv.items, .environ_map = app.environ });
        return app.fail("cannot enter a user namespace with unshare(1): {t}", .{e});
    }

    // -- installing onto a disk ------------------------------------------------

    fn cmdInstallSystem(app: *App, args: []const []const u8) !void {
        if (args.len != 0 or (app.opts.list == (app.opts.disk != null)))
            return app.fail("usage: dave install-system --list [--json] | --disk DISK [--json]", .{});
        if (app.opts.json) {
            // Events alone on standard output; everything said for people
            // (and what the programs dave runs say) on standard error.
            app.events = app.out;
            app.out = app.err;
        }
        if (app.opts.list) return app.listDisks();
        app.installSystem(app.opts.disk.?) catch |e| {
            app.event("error", if (app.last_error.len > 0) app.last_error else @errorName(e), null);
            return e;
        };
        app.event("done", "joe Linux is installed", 1);
    }

    fn findDisks(app: *App) ![]install_system.Disk {
        var diag: command.Diagnostic = .{};
        const listing = command.run(app.arena, app.io, &install_system.lsblk_argv, .{ .capture = true }, &diag) catch |e| switch (e) {
            error.CommandFailed => return app.fail("{s}", .{diag.message}),
            else => return e,
        };
        const medium = install_system.mountSource(app.readAbsolute("/proc/self/mountinfo") orelse "", install_system.medium_mount);
        return install_system.parseDisks(app.arena, listing, try install_system.readById(app.arena, app.io), medium) catch
            app.fail("cannot understand what lsblk says about this computer's disks", .{});
    }

    fn listDisks(app: *App) !void {
        const disks = try app.findDisks();
        if (app.events) |w| {
            std.json.Stringify.value(.{ .disks = disks }, .{}, w) catch {};
            w.writeByte('\n') catch {};
            return;
        }
        for (disks) |d| {
            try app.say("{s}  {d} GB  {s}{s}{s}", .{
                d.path,                                     d.size / 1_000_000_000, if (d.model.len > 0) d.model else "-",
                if (d.usable) "" else "  cannot be used: ", d.reason,
            });
        }
    }

    fn installSystem(app: *App, disk_arg: []const u8) !void {
        if (linux.getuid() != 0) return app.fail("installing joe Linux needs root", .{});
        const medium_dir = app.opts.from orelse install_system.medium_dir;
        const spec_path = try std.fs.path.join(app.arena, &.{ medium_dir, install_system.install_file });
        const spec_text = app.readAbsolute(spec_path) orelse
            return app.fail("{s} is missing: is this joe Linux's installation medium?", .{spec_path});
        const medium = install_system.parseMedium(app.arena, spec_text) catch return app.fail("{s} is unreadable", .{spec_path});
        var packages: std.ArrayList([]const u8) = .empty;
        try packages.appendSlice(app.arena, medium.packages);
        try packages.appendSlice(app.arena, app.opts.with.items);

        // The disk, as a listing would show it: whatever a listing refuses,
        // installing refuses too.
        const device = Io.Dir.cwd().realPathFileAlloc(app.io, disk_arg, app.arena) catch
            return app.fail("there is no disk {s}", .{disk_arg});
        const disk = for (try app.findDisks()) |d| {
            if (std.mem.eql(u8, d.device, device)) break d;
        } else return app.fail("{s} is not a disk this system can install onto", .{disk_arg});
        if (!disk.usable) return app.fail("{s} cannot be used: {s}", .{ disk_arg, disk.reason });

        var lock_file = try app.lock();
        defer lock_file.close(app.io);
        const live_config = repo.loadConfig(app.arena, app.io, try app.openDir("/")) catch
            return app.fail("this system's {s} is unreadable", .{repo.config_path});
        if (live_config.repos.len == 0) return app.fail("this system has no repositories configured ({s})", .{repo.config_path});

        const plan = provision.Plan.new(app.io, provision.default_esp_size, null);
        var disks: install_system.Disks = .{ .arena = app.arena, .io = app.io };
        defer disks.unmountTarget();

        app.step(0.01, "Erasing {s}", .{if (disk.model.len > 0) disk.model else device});
        const parts = disks.partition(device, plan) catch return app.fail("{s}", .{disks.diag.message});
        app.step(0.03, "Creating file systems", .{});
        disks.format(parts.esp, parts.root) catch return app.fail("{s}", .{disks.diag.message});
        disks.mountTarget(parts.esp, parts.root) catch return app.fail("{s}", .{disks.diag.message});

        // The new system installs from the medium, trusting what this one
        // trusts.
        const target_path = install_system.target_mount;
        var target = try app.openDir(target_path);
        defer target.close(app.io);
        try target.createDirPath(app.io, repo.keys_path);
        {
            var keys = try app.openDir("/" ++ repo.keys_path);
            defer keys.close(app.io);
            var it = keys.iterate();
            while (try it.next(app.io)) |e| {
                if (e.kind != .file) continue;
                try keys.copyFile(e.name, target, try std.fs.path.join(app.arena, &.{ repo.keys_path, e.name }), app.io, .{});
            }
            var config: std.ArrayList(image.RepoArg) = .empty;
            for (live_config.repos) |r| {
                const dir = try std.fs.path.join(app.arena, &.{ medium_dir, install_system.repos_dir, r.name });
                try config.append(app.arena, .{ .name = r.name, .dir = dir, .url = r.url, .key = "" });
            }
            try target.writeFile(app.io, .{ .sub_path = repo.config_path, .data = try image.reposZon(app.arena, config.items, .build) });
        }

        app.step(0.05, "Installing packages", .{});
        var reporter: InstallProgress = .{ .app = app };
        app.progress = reporter.interface();
        app.opts.root = target_path;
        app.opts.cache = null;
        try app.cmdChange(.install, packages.items);
        app.progress = null;

        app.step(0.88, "Sealing the installed files", .{});
        try app.cmdSeal();

        app.step(0.94, "Making the disk bootable", .{});
        try target.writeFile(app.io, .{ .sub_path = "etc/fstab", .data = try provision.fstab(app.arena, plan) });
        const kernel = deploy.findKernelIn(app.arena, app.io, target) catch return app.fail("the installed system has no kernel", .{});
        const consoles = try provision.consoleArgs(app.arena, app.readAbsolute("/proc/cmdline") orelse "");
        {
            var esp = try app.openDir(target_path ++ "/" ++ provision.esp_mount);
            defer esp.close(app.io);
            provision.writeEsp(app.arena, app.io, esp, .{ .root = target, .kernel_path = kernel }, try provision.cmdline(app.arena, plan, consoles)) catch |e|
                return app.fail("cannot write the EFI system partition: {t}", .{e});
        }
        // From now on the installed system takes its packages from where this
        // one would.
        try target.writeFile(app.io, .{ .sub_path = repo.config_path, .data = app.readAbsolute("/" ++ repo.config_path) orelse "" });
        target.deleteTree(app.io, "var/cache/dave") catch {};
        // Tell the firmware where the boot loader is. A firmware that will not
        // be told still finds it at the removable-media path.
        var diag: command.Diagnostic = .{};
        if (command.run(app.arena, app.io, &.{
            "bootctl",                "install",         "--root=" ++ target_path,    "--esp-path=/efi",
            "--install-source=image", "--variables=yes", "--make-entry-directory=no", "--graceful",
        }, .{}, &diag)) |_| {} else |_| {
            app.say("note: the firmware was not told about the new system ({s}); it starts from the disk's removable-media path", .{diag.message}) catch {};
        }

        app.step(0.99, "Finishing", .{});
        _ = linux.sync();
        disks.unmountTarget();
    }

    const InstallProgress = struct {
        app: *App,

        fn interface(p: *InstallProgress) txn.Progress {
            return .{ .context = p, .report = onPackage };
        }

        fn onPackage(ctx: *anyopaque, done: usize, total: usize, name: []const u8) void {
            const p: *InstallProgress = @ptrCast(@alignCast(ctx));
            const fraction = 0.05 + 0.83 * @as(f64, @floatFromInt(done)) / @as(f64, @floatFromInt(@max(total, 1)));
            const message = std.fmt.allocPrint(p.app.arena, "Installing packages ({d} of {d}: {s})", .{ done, total, name }) catch return;
            p.app.event("progress", message, fraction);
        }
    };

    /// `dave --chroot-exec <dir> [--tmpfs=PATH]... <program> [args...]`: used
    /// to run triggers inside a root other than the running one.
    fn chrootExec(app: *App, args: []const []const u8) !void {
        if (args.len < 2) return app.fail("--chroot-exec needs a directory and a program", .{});
        const dir = try app.arena.dupeSentinel(u8, args[0], 0);
        var program = args[1..];
        var covered: std.ArrayList([]const u8) = .empty;
        while (program.len > 0 and std.mem.startsWith(u8, program[0], triggers.tmpfs_flag)) : (program = program[1..]) {
            try covered.append(app.arena, program[0][triggers.tmpfs_flag.len..]);
        }
        if (program.len == 0) return app.fail("--chroot-exec needs a program", .{});

        // Programs expect /proc, /dev and /sys. They are bound into the root
        // inside a mount namespace of this process's own, so nothing outlives
        // the trigger and the host's mount table is never touched. If the
        // namespace cannot be made, the program simply runs without them.
        const CLONE_NEWNS = 0x00020000;
        const isolated = linux.errno(linux.unshare(CLONE_NEWNS)) == .SUCCESS;
        if (isolated) {
            _ = linux.mount(null, "/", null, linux.MS.REC | linux.MS.PRIVATE, 0);
            for ([_][]const u8{ "proc", "dev", "sys" }) |name| {
                const source = try std.fmt.allocPrintSentinel(app.arena, "/{s}", .{name}, 0);
                const target = try std.fmt.allocPrintSentinel(app.arena, "{s}/{s}", .{ args[0], name }, 0);
                _ = linux.mount(source, target, null, linux.MS.BIND | linux.MS.REC, 0);
            }
        }
        // The directories a booted system mounts the shared subvolumes on
        // (triggers.RunOptions.shared). These are not optional: without them
        // the program would leave its work hidden in the root.
        for (covered.items) |name| {
            if (!isolated) return app.fail("cannot cover {s} in {s}: no mount namespace of its own", .{ name, args[0] });
            const target = try std.fmt.allocPrintSentinel(app.arena, "{s}/{s}", .{ args[0], name }, 0);
            Io.Dir.cwd().createDirPath(app.io, target) catch {};
            const rc = linux.mount("tmpfs", target, "tmpfs", linux.MS.NOSUID | linux.MS.NODEV, @intFromPtr(@as([*:0]const u8, "mode=0755")));
            if (linux.errno(rc) != .SUCCESS) return app.fail("cannot cover {s} in {s}: {t}", .{ name, args[0], linux.errno(rc) });
        }

        if (linux.errno(linux.chroot(dir)) != .SUCCESS) return app.fail("cannot chroot to {s}", .{args[0]});
        if (linux.errno(linux.chdir("/")) != .SUCCESS) return app.fail("cannot enter {s}", .{args[0]});
        const e = std.process.replace(app.io, .{ .argv = program });
        return app.fail("cannot run {s} in {s}: {t}", .{ program[0], args[0], e });
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
        .environ = init.environ_map,
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
