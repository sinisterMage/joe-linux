build() {
    # xmlto and fop (documentation) are not part of joe Linux.
    # The manual pages are shipped ready-made.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libXtst-$PKG_VERSION" \
        --without-xmlto \
        --without-fop
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
