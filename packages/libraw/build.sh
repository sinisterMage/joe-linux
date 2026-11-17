# Following the book's libraw page.
build() {
    # The book's options, except --enable-jasper: this release's configure
    # has no such option (and jasper has no recipe). zlib and OpenMP are
    # stated rather than left to their defaults. The examples are the
    # small raw-identify, dcraw_emu and similar tools.
    ./configure --prefix=/usr \
        --enable-jpeg \
        --enable-lcms \
        --enable-zlib \
        --enable-openmp \
        --enable-examples \
        --disable-static \
        --docdir=/usr/share/doc/libraw-0.22.3
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
