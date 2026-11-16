# Not in the book: the newest upstream release, built with cargo as its
# README describes (cargo install --locked cargo-deny). Upstream publishes
# checksums only for its binary archives, none for the source archive.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # The system libzstd rather than the copy in zstd-sys.
    export ZSTD_SYS_USE_PKG_CONFIG=1
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/cargo-deny "$DESTDIR/usr/bin/cargo-deny"
}
