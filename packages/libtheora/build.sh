# Not in the book (Beyond LFS dropped its libtheora page): the newest
# upstream release, built as its README says.
build() {
    # The examples (which would link libvorbis, libpng, libtiff and SDL) are
    # not installed anyway; the API documentation and the specification
    # need Doxygen and LaTeX.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-examples \
        --disable-doc \
        --disable-spec
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
