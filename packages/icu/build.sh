build() {
    cd source
    ./configure --prefix=/usr
    make
}

package() {
    cd source
    make DESTDIR="$DESTDIR" install
}
