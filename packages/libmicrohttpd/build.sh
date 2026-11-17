# Not in the book: the newest upstream release, built as its README says.
build() {
    # HTTPS through GnuTLS (new enough that libgcrypt need not be
    # initialised, so it is not linked). The test tools, examples and the
    # curl-based tests are not built.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-https \
        --with-gnutls \
        --disable-tools \
        --disable-examples \
        --disable-curl
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
