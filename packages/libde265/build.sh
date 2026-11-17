# Following the book's libde265 page.
build() {
    # The book's options, plus: dec265's SDL display is off (SDL2 has no
    # recipe), as is sherlock265 (Qt 5 and FFmpeg); the experimental
    # encoder stays off, as upstream ships it.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_SDL=OFF \
        -D ENABLE_DECODER=ON \
        -D ENABLE_ENCODER=OFF \
        -D ENABLE_SHERLOCK265=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
