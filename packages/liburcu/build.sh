build() {
    ./configure --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/liburcu-0.15.7
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
