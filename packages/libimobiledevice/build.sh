# Not in the book: the newest upstream release, built as its README says
# (the release tarball carries a generated configure).
build() {
    # OpenSSL is the TLS library (rather than GnuTLS or MbedTLS). The
    # Python bindings are built with Cython on top of libplist's .pxd file;
    # configure finds Cython by itself and has no switch to insist on it
    # (--with-cython would turn the bindings off).
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --with-openssl \
        --without-gnutls \
        --without-mbedtls \
        PYTHON=/usr/bin/python3
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # Fail rather than ship without the bindings if Cython was not found.
    compgen -G "$DESTDIR/usr/lib/python3*/site-packages/imobiledevice*.so" >/dev/null
}
