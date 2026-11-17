# Not in the book: the newest upstream release, built as its INSTALL
# says. All three libraries: librevenge, librevenge-stream (OLE2 and zip
# containers) and librevenge-generators (the text, raw, SVG and HTML
# output the filters' conversion tools use). No unit tests (they need
# cppunit), no Doxygen documentation, no -Werror.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-werror \
        --disable-tests \
        --without-docs \
        --enable-streams \
        --enable-generators
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
