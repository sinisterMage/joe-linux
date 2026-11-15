# The one recipe that packages an upstream binary instead of building from
# source, by decision: bun's build runs an existing bun to generate code,
# needs upstream's own Zig fork, and downloads a prebuilt WebKit. This is
# upstream's release build for x86_64 "baseline" (no AVX2 needed), so it runs
# on every x86_64 machine joe Linux supports.

# Already stripped by upstream; stripping again gains nothing.
NOSTRIP=1

unpack() {
    bsdtar -xf "$SOURCES/$PKG_SOURCE" --strip-components=1 --no-same-owner --no-same-permissions
}

package() {
    install -Dm755 bun "$DESTDIR/usr/bin/bun"
    # bunx is bun itself, which behaves as `bun x` when called by that name.
    ln -s bun "$DESTDIR/usr/bin/bunx"
}
