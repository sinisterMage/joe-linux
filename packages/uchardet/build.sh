# Following the book's uchardet page. mpv uses it to guess the character
# encoding of text subtitles. The uchardet command-line tool is built too.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_STATIC=OFF \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -W no-author ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
