# Not in the book: the newest upstream release, built with cargo as its
# README describes. Upstream publishes no checksum for the source archive.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    # The build script regenerates the shell completions in
    # contrib/completions.
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/zoxide "$DESTDIR/usr/bin/zoxide"
    install -d "$DESTDIR/usr/share/man/man1"
    install -m644 man/man1/*.1 "$DESTDIR/usr/share/man/man1/"
    install -Dm644 contrib/completions/zoxide.bash "$DESTDIR/usr/share/bash-completion/completions/zoxide"
    install -Dm644 contrib/completions/_zoxide "$DESTDIR/usr/share/zsh/site-functions/_zoxide"
    install -Dm644 contrib/completions/zoxide.fish "$DESTDIR/usr/share/fish/vendor_completions.d/zoxide.fish"
}
