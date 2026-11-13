build() {
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libXinerama-$PKG_VERSION"
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
