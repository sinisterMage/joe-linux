# Not in the book: the newest upstream release, built with cargo as its
# README describes (cargo install oxipng). Curtail runs it.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # Default features (binary, parallel, zopfli) plus system-libdeflate.
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked --features system-libdeflate
}

package() {
    install -Dm755 target/release/oxipng "$DESTDIR/usr/bin/oxipng"
}
