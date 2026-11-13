build() {
    # Client ids are generated with libuuid (util-linux).
    # xmlto and fop (documentation) are not part of joe Linux.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libSM-$PKG_VERSION" \
        --with-libuuid \
        --without-xmlto \
        --without-fop
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
