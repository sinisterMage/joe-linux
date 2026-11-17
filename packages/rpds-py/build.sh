# Not in the book: the newest release on PyPI, built as a wheel with its
# maturin backend and installed like the book's Python modules.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    export MATURIN_NO_INSTALL_RUST=1
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    export MATURIN_PEP517_ARGS="--locked"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist rpds_py
}
