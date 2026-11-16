# Not in the book: the newest upstream release, built with cargo as its
# README describes. Upstream publishes no checksum for the source archive,
# and has no manual page or completions.
build() {
    # Keep cargo's home inside the build directory rather than in root's
    # home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # --locked: Cargo.lock lists no dependencies, so nothing is fetched.
    cargo build --release --locked --offline
}

package() {
    install -Dm755 target/release/shellharden "$DESTDIR/usr/bin/shellharden"
}
