build() {
    # --disable-open-zfile: do not read and write compressed pixmaps by running
    # gzip and (un)compress. The sxpm viewer is built because libXt and libXext
    # are present. The unit tests (which need glib) are not run.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libXpm-$PKG_VERSION" \
        --disable-open-zfile \
        --disable-unit-tests
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
