# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # The library only: minilzip, the small test program, is not
    # installed (lzip, the full program, is a separate project).
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --disable-static \
        --disable-ldconfig
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
