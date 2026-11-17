# Not in the book: the newest upstream release, built with cargo as its
# crate manifest builds it (the README in the crate does not describe
# building). Curtail runs it.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # Default features: lcms2 (colour profiles), linked dynamically like
    # libpng. --locked: build exactly the crate versions in upstream's
    # Cargo.lock.
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/pngquant "$DESTDIR/usr/bin/pngquant"
}
