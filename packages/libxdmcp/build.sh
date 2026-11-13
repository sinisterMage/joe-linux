build() {
    # xmlto and fop (documentation) are not part of joe Linux.
    # libbsd (arc4random_buf) is not either; glibc has the function itself.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir='${datadir}'/doc/libXdmcp-$PKG_VERSION \
        --without-xmlto \
        --without-fop \
        --disable-unit-tests
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
