build() {
    mkdir build
    cd build
    # The book's command, plus CMAKE_INSTALL_LIBDIR so that nothing can pick
    # lib64, and no test programs.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CARES_BUILD_TESTS=OFF \
        ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
