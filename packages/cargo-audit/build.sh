# Not in the book: the newest upstream release, built with cargo as its
# README describes (cargo install cargo-audit; default features: binary
# scanning, and the advisory database fetched with gix over reqwest and
# rustls). Upstream publishes no checksum for the source archive.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # AWS-LC (rustls's crypto provider) has no recipe: aws-lc-sys builds its
    # bundled copy with cc rather than CMake, and does not look for an
    # installed one.
    export AWS_LC_SYS_USE_SYSTEM=0
    export AWS_LC_SYS_CMAKE_BUILDER=0
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    # The workspace holds the rustsec libraries too; build only the program.
    cargo build --release --locked -p cargo-audit
}

package() {
    install -Dm755 target/release/cargo-audit "$DESTDIR/usr/bin/cargo-audit"
}
