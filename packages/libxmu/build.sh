build() {
    # xmlto and fop (documentation) are not part of joe Linux.
    # The unit tests (which need glib) are not run.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libXmu-$PKG_VERSION" \
        --without-xmlto \
        --without-fop \
        --disable-unit-tests
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
