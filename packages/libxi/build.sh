build() {
    # xmlto, fop and asciidoc are not part of joe Linux. The manual pages are
    # shipped ready-made.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libXi-$PKG_VERSION" \
        --without-xmlto \
        --without-fop \
        --without-asciidoc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
