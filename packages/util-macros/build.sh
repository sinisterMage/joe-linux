build() {
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static
}

package() {
    make DESTDIR="$DESTDIR" install
}
