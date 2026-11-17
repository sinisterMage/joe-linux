# Not in the book: the newest release on PyPI, built as a wheel with its
# maturin backend and installed like the book's Python modules, linking the
# system OpenSSL (never a vendored copy: OPENSSL_STATIC is unset and the
# crate's "vendored" feature is off).
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    export MATURIN_NO_INSTALL_RUST=1
    # --locked: build exactly the crate versions in upstream's Cargo.lock
    # (pyproject.toml also says locked = true).
    export MATURIN_PEP517_ARGS="--locked"
    # The interpreter the build script runs to generate the cffi binding.
    export PYO3_PYTHON=/usr/bin/python3
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist cryptography
}
