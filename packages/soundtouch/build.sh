build() {
    # The book's commands. Samples stay floating point (the default), which
    # is what Audacity and the other users expect; no OpenMP, as in the book.
    ./bootstrap
    ./configure --prefix=/usr \
        --disable-static \
        --disable-openmp
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
