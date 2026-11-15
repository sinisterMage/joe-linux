build() {
    mkdir build
    cd build
    # The book's command; the library is headers only, so nothing is
    # compiled.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D JSON_BuildTests=OFF \
        -G Ninja ..
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
