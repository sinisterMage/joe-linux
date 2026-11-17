# Not in the book: upstream's npm package, laid out where
# "npm install -g pnpm" would put it (like packages/typescript). pnpm is
# written in TypeScript and bundled with its own tools, so the published
# bundle is the practical way to have it.
#
# 11.28.12 is the newest release of the 11 series. pnpm 12 is published as
# prebuilt native executables (the @pnpm/exe.* packages), which this recipe
# would have to build from source instead. The 11 series is what
# Prometheus's web UI asks for (its CI accepts any pnpm below 13), and its
# lockfile format (9.0) is the same.
package() {
    local dir=$DESTDIR/usr/lib/node_modules/pnpm
    install -d "$dir" "$DESTDIR/usr/bin"
    cp -r bin dist package.json LICENSE README.md "$dir/"

    # Prebuilt binaries for other systems, never loaded on Linux: the
    # reflink copy-on-write bindings for macOS and Windows (there is none
    # for Linux; pnpm falls back to hard links and copies) and the Windows
    # process lister.
    rm -r "$dir"/dist/node_modules/@reflink/reflink-{darwin-arm64,darwin-x64,win32-arm64-msvc,win32-x64-msvc}
    rm -r "$dir/dist/vendor"

    chmod 755 "$dir"/bin/pnpm.mjs "$dir"/bin/pnpx.mjs
    # The four commands package.json declares: pn and pnx are short names
    # for pnpm and pnpx.
    ln -s ../lib/node_modules/pnpm/bin/pnpm.mjs "$DESTDIR/usr/bin/pnpm"
    ln -s ../lib/node_modules/pnpm/bin/pnpx.mjs "$DESTDIR/usr/bin/pnpx"
    ln -s ../lib/node_modules/pnpm/bin/pnpm.mjs "$DESTDIR/usr/bin/pn"
    ln -s ../lib/node_modules/pnpm/bin/pnpx.mjs "$DESTDIR/usr/bin/pnx"
}
