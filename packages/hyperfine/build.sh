# Not in the book: the newest upstream release, built with cargo as its
# release workflow does. Upstream publishes no checksum for the source
# archive.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # hyperfine's build script writes the shell completions here rather than
    # into cargo's hashed OUT_DIR.
    export SHELL_COMPLETIONS_DIR="$PWD/completions"
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/hyperfine "$DESTDIR/usr/bin/hyperfine"
    install -Dm644 doc/hyperfine.1 "$DESTDIR/usr/share/man/man1/hyperfine.1"
    install -Dm644 completions/hyperfine.bash "$DESTDIR/usr/share/bash-completion/completions/hyperfine"
    install -Dm644 completions/_hyperfine "$DESTDIR/usr/share/zsh/site-functions/_hyperfine"
    install -Dm644 completions/hyperfine.fish "$DESTDIR/usr/share/fish/vendor_completions.d/hyperfine.fish"
}
