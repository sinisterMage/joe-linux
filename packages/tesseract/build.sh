# Following the book's tesseract page. Like the book, it builds the
# library and the tesseract program, not the training tools (make
# training), which are what ICU and Pango would be for.
build() {
    ./autogen.sh
    # The book's options, plus libarchive and libcurl required rather
    # than detected. --disable-doc: with asciidoctor present configure
    # would install the manual pages of every training tool as well, so
    # only tesseract(1) is made, in package().
    ./configure --prefix=/usr \
        --disable-static \
        --with-archive \
        --with-curl \
        --disable-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    asciidoctor -b manpage -o tesseract.1 doc/tesseract.1.asc
    install -Dm644 tesseract.1 "$DESTDIR/usr/share/man/man1/tesseract.1"
}
