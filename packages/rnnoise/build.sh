# Not in the book: the newest upstream release, built as its README says.
# The SSE4.1 and AVX2 code paths are built and chosen at run time
# (--enable-x86-rtcd), as Arch does. The demo program and the doxygen API
# documentation are not built.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --enable-x86-rtcd \
        --disable-examples \
        --disable-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
