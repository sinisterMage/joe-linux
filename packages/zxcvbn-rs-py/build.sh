# Not in the book: the newest release on PyPI, built as a wheel with its
# maturin backend and installed like the book's Python modules.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    export MATURIN_NO_INSTALL_RUST=1
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    export MATURIN_PEP517_ARGS="--locked"
    # The locked pyo3 (0.27) knows Python only up to 3.14; this lets it
    # build for 3.15 through the stable ABI.
    export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist zxcvbn_rs_py
}
