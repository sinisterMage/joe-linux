# Following the book's leptonica page.
build() {
    ./autogen.sh
    # The book's options, plus: every image library stated (configure
    # fails if one asked for is missing), and --disable-programs. Without
    # it the build compiles some 300 regression-test programs and installs
    # nine of them under generic names (fileinfo, convertformat,
    # imagetops, ...); Tesseract needs only the library.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-programs \
        --with-zlib \
        --with-libpng \
        --with-jpeg \
        --with-giflib \
        --with-libtiff \
        --with-libwebp \
        --with-libwebpmux \
        --with-libopenjpeg
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
