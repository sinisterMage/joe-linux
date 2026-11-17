# Following the book's utfcpp page. taglib is built against it.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr ..
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
