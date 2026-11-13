build() {
    # xmlto and fop (documentation) are not part of joe Linux.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libX11-$PKG_VERSION" \
        --without-xmlto \
        --without-fop
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
