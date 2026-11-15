# Not in the book: the newest weekly release (tagged 2026-11-09; dave
# versions cannot contain dashes), built as upstream's xtask dist builds
# the server. Upstream publishes no checksum for the archive.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # What xtask dist sets: the version rust-analyzer --version reports
    # (without it, the server asks users to report bugs as from a source
    # build), and thin LTO with one codegen unit.
    export CFG_RELEASE=2026-11-09
    export CARGO_PROFILE_RELEASE_LTO=thin
    export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    # jemalloc, as upstream's Linux releases use, built from the copy in
    # tikv-jemalloc-sys (with make). No profile-guided optimisation: its
    # training run downloads a crate.
    cargo build --release --locked \
        --manifest-path crates/rust-analyzer/Cargo.toml \
        --bin rust-analyzer --features jemalloc
}

package() {
    install -Dm755 target/release/rust-analyzer "$DESTDIR/usr/bin/rust-analyzer"
}
