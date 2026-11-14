build() {
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
