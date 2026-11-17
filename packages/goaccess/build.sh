# Not in the book: the newest upstream release, built as its README says.
build() {
    # Wide-character ncurses; OpenSSL for the real-time HTML report's
    # WebSocket over TLS (--ssl-cert); zlib to read gzipped logs; lines of
    # any length (--with-getline). Off: GeoIP country and city lookup,
    # which needs libmaxminddb (or the legacy GeoIP library), neither
    # packaged.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --enable-utf8 \
        --with-openssl \
        --with-zlib \
        --with-getline \
        --disable-geoip
    make
}

package() {
    # Installs goaccess, its manual page, the translations and the default
    # configuration in /etc/goaccess.
    make DESTDIR="$DESTDIR" install
}
