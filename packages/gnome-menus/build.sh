build() {
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --enable-introspection=yes
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
