# Not in the book: the newest upstream release, built with cargo as its
# release workflow builds the watchexec-cli crate (default features).
# Upstream publishes checksums only for its binary archives, none for the
# source archive.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked -p watchexec-cli
}

package() {
    install -Dm755 target/release/watchexec "$DESTDIR/usr/bin/watchexec"
    # The manual page and completions upstream generated for the release and
    # ships in the repository, installed where its own deb and rpm
    # packages put them.
    install -Dm644 doc/watchexec.1 "$DESTDIR/usr/share/man/man1/watchexec.1"
    install -Dm644 completions/bash "$DESTDIR/usr/share/bash-completion/completions/watchexec"
    install -Dm644 completions/zsh "$DESTDIR/usr/share/zsh/site-functions/_watchexec"
    install -Dm644 completions/fish "$DESTDIR/usr/share/fish/vendor_completions.d/watchexec.fish"
}
