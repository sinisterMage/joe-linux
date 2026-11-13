build() {
    # The manual pages are shipped ready-made; xmlto would only regenerate them.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libXcomposite-$PKG_VERSION" \
        --without-xmlto
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
