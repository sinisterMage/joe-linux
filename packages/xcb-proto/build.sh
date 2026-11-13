build() {
    PYTHON=python3 ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static
}

package() {
    make DESTDIR="$DESTDIR" install
}
