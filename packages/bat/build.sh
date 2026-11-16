# Not in the book: the newest upstream release, built with cargo as its
# README and release workflow describe (default features: the application
# and Git support), against the system's libgit2, Oniguruma and zlib.
# Upstream publishes no checksum for the source archive.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # Link the libgit2 and Oniguruma that pkg-config finds rather than
    # building the copies inside libgit2-sys and onig_sys. libz-sys uses the
    # system zlib by itself.
    export LIBGIT2_NO_VENDOR=1
    export RUSTONIG_SYSTEM_LIBONIG=1
    # bat's build script renders the manual page and shell completions from
    # templates; have it write them to a known place instead of cargo's
    # hashed OUT_DIR.
    export BAT_ASSETS_GEN_DIR="$PWD/gen"
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/bat "$DESTDIR/usr/bin/bat"
    install -Dm644 gen/assets/manual/bat.1 "$DESTDIR/usr/share/man/man1/bat.1"
    install -Dm644 gen/assets/completions/bat.bash "$DESTDIR/usr/share/bash-completion/completions/bat"
    install -Dm644 gen/assets/completions/bat.zsh "$DESTDIR/usr/share/zsh/site-functions/_bat"
    install -Dm644 gen/assets/completions/bat.fish "$DESTDIR/usr/share/fish/vendor_completions.d/bat.fish"
}
