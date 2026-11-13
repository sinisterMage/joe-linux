build() {
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" docdir=/usr/share/doc/libatasmart-0.19 install
}
