build() {
    # No plain-text README (it needs lynx) and no example programs.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-lynx \
        --disable-examples
    make
}

package() {
    make docdir=/usr/share/doc/libdaemon-0.14 DESTDIR="$DESTDIR" install
}
