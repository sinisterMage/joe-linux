# Not in the book: the newest upstream release, built as doc/building.rst
# describes.
build() {
    # - Only the shared library and the botan program; the test suite is
    #   not built and no static library is made.
    # - The manual page is made with rst2man (docutils); the HTML handbook
    #   would need Sphinx.
    # - Boost (only for the Asio-based TLS stream and the TLS proxy and
    #   HTTP server commands) is left out, as are the TPM and ESDM modules
    #   and the Python ctypes module.
    # - The system trust store is make-ca's bundle; configure only accepts
    #   it if it is readable, which is why make-ca is in build_depends.
    python3 configure.py \
        --prefix=/usr \
        --libdir=lib \
        --cc=gcc \
        --build-targets=shared,cli \
        --with-zlib \
        --with-bzip2 \
        --with-lzma \
        --with-sqlite3 \
        --without-boost \
        --without-tpm \
        --without-tpm2 \
        --without-esdm_rng \
        --system-cert-bundle=/etc/pki/tls/certs/ca-bundle.crt \
        --with-documentation \
        --with-rst2man \
        --without-sphinx \
        --without-doxygen \
        --without-pdf \
        --no-install-python-module \
        --distribution-info="joe Linux"
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
