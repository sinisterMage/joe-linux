build() {
    ./configure --prefix=/usr \
        --with-python3 \
        --with-tools \
        --without-gtk-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
