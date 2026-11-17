# Following the book's libaio page.
prepare() {
    # Do not install the static library.
    sed -i '/install.*libaio.a/s/^/#/' src/Makefile
}

build() {
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
