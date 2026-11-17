# Not in the book: the newest upstream release (0.4.41 is still current),
# built with its GNU build files (Project/GNU/Library) as its ReadMe says.
# Unicode and large-file support are on by default.
build() {
    cd Project/GNU/Library
    sh ./autogen.sh
    ./configure --prefix=/usr \
        --enable-shared \
        --disable-static
    make
}

package() {
    cd Project/GNU/Library
    make DESTDIR="$DESTDIR" install
}
