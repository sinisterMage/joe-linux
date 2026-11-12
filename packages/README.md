# joe Linux package recipes

One directory per package. Each holds two files.

## `package.zon`

```zon
.{
    .name = "zlib",
    .version = "1.4",            // upstream version, exactly as upstream writes it
    .release = 1,                // bump when the recipe changes
    .description = "One line, no trailing full stop",
    .license = "SPDX expression",
    .sources = .{
        // The first source is unpacked automatically. Later ones (patches,
        // extra tarballs) are available as $SOURCES/<file name>.
        .{ .url = "https://...", .sha256 = "<64 hex digits>" },
    },
    .depends = .{ "glibc", "zstd >=1.5" },   // needed at run time
    .build_depends = .{ "meson" },           // needed only to build
}
```

`.file = "name"` on a source overrides the file name taken from the URL.

## `build.sh`

A bash file defining functions. It is sourced, not executed, so it must not run
anything at top level.

| Function  | Default            | Purpose                                   |
|-----------|--------------------|-------------------------------------------|
| `unpack`  | extract first source, stripping its top directory | rarely overridden |
| `prepare` | nothing            | patches, fixes to the source              |
| `build`   | nothing            | configure and compile                     |
| `package` | required           | install into `$DESTDIR`                   |

All four run in the unpacked source directory, as root in a user namespace,
inside the build root, with no network. Any command that fails aborts the build.

Available variables: `DESTDIR`, `SOURCES`, `PKG_NAME`, `PKG_VERSION`,
`PKG_RELEASE`, `JOBS`. `MAKEFLAGS` is already set to `-j$JOBS`.

## Rules

- **Everything goes through `$DESTDIR`.** Never write to `/usr`, `/etc` and so
  on directly: the build root is shared by every build.
- Install under `/usr`. `/bin`, `/sbin` and `/lib` are symlinks to `usr/bin`,
  `usr/sbin` and `usr/lib`, owned by `joe-filesystem`; a package must never
  contain a path starting with `bin/`, `sbin/` or `lib/`. Libraries go in
  `/usr/lib` (never `lib64`): pass `--libdir=/usr/lib` where upstream would
  choose otherwise.
- Files are owned by root. Never `chown` or `chgrp` to anything else and never
  call `setcap`; ownership other than root is set up at run time by
  `sysusers.d` and `tmpfiles.d`. Set-uid is fine: `chmod 4755`.
- Nothing under `/var`, `/run` or `/tmp` is packaged (the driver removes it):
  `/var` is shared between deployments and the other two are temporary. Ship a
  `usr/lib/tmpfiles.d/NAME.conf` for anything that must exist there.
- No install scripts exist. If something must run after installation (a cache
  rebuild), ship a trigger in `usr/lib/dave/triggers/NAME.zon`:
  `.{ .paths = .{"usr/lib/"}, .exec = .{"/usr/bin/ldconfig"} }`.
- Do not run test suites.
- Do not strip, delete `.la` files or remove `usr/share/doc` and
  `usr/share/info` yourself; the build driver does that for every package. Set
  `NOSTRIP=1` at the top of `build.sh` to keep symbols.
- Static libraries are not shipped unless something needs them.
