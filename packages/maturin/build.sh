# Following the book's maturin (general/python-dependencies). setup.py builds
# the maturin binary with setuptools-rust: cargo build --locked (upstream's
# Cargo.lock) with --no-default-features, the minimal build for PEP 517
# (no upload, cross-compilation or scaffolding support).
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # Link the system libzstd that pkg-config finds rather than building the
    # copy inside the zstd-sys crate.
    export ZSTD_SYS_USE_PKG_CONFIG=1
    # cargo is installed: never fetch a private Rust toolchain.
    export MATURIN_NO_INSTALL_RUST=1
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist maturin
}
