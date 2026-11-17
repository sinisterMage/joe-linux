# Not in the book: the newest upstream release, built as its README.rst
# says.
build() {
    # The TLS backend is OpenSSL's own QUIC API (SSL_set_quic_tls_cbs,
    # OpenSSL 3.5 and later), which gives libngtcp2_crypto_ossl; the other
    # backends (GnuTLS, BoringSSL, picotls, wolfSSL) are off.
    # --enable-lib-only leaves out the example client and server, and with
    # them libev, nghttp3, brotli and jemalloc.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --disable-static \
        --enable-lib-only \
        --with-openssl \
        --without-gnutls \
        --without-boringssl \
        --without-picotls \
        --without-wolfssl
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
