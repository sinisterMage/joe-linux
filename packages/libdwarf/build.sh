# Not in the book: the newest upstream release, built with its configure
# script as README.md describes.
build() {
    # The producer library (libdwarfp) and dwarfgen, which exists to test
    # it, are off as upstream has them; so are the examples.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --enable-shared \
        --disable-static \
        --enable-decompression \
        --disable-dwarfgen \
        --disable-dwarfexample
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
