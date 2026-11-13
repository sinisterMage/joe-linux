build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # --locked: build exactly the crate versions in the shipped Cargo.lock.
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/cbindgen "$DESTDIR/usr/bin/cbindgen"
}
