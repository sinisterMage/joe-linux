# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # TLS with GnuTLS (upstream's default; certificates from the system trust
    # store), WebDAV listings with Expat, internationalised host names with
    # libidn2, and glibc's regex rather than the bundled gnulib copy. No
    # SOCKS libraries, no libval (DNSSEC) and no loadable protocol modules.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --with-gnutls \
        --without-openssl \
        --with-expat \
        --with-zlib=/usr \
        --with-libidn2 \
        --with-readline \
        --without-included-regex \
        --without-modules \
        --without-socks \
        --without-socks5 \
        --without-socksdante \
        --without-dnssec-local-validation
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
