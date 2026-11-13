build() {
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
