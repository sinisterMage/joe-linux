# Not in the book: the newest upstream release, built with cargo as its
# publish workflow builds it, limited to the sd-cli crate (the program; the
# workspace also holds the library and the xtask helper). Upstream
# publishes no checksum for the source archive.
#
# The v1.1.0 tag did not bump the workspace version in Cargo.toml (still
# 1.0.0, and 1.1.0 is not on crates.io), so "sd --version" says 1.0.0, as
# upstream's own release binaries do. Changing it here would contradict
# Cargo.lock and so break --locked.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked -p sd-cli
}

package() {
    install -Dm755 target/release/sd "$DESTDIR/usr/bin/sd"
    # The manual page and completions upstream generates (cargo xtask gen)
    # and keeps in gen/ for packagers.
    install -Dm644 gen/sd.1 "$DESTDIR/usr/share/man/man1/sd.1"
    install -Dm644 gen/completions/sd.bash "$DESTDIR/usr/share/bash-completion/completions/sd"
    install -Dm644 gen/completions/_sd "$DESTDIR/usr/share/zsh/site-functions/_sd"
    install -Dm644 gen/completions/sd.fish "$DESTDIR/usr/share/fish/vendor_completions.d/sd.fish"
}
