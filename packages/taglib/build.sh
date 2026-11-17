# Following the book's taglib page. The C bindings (libtag_c) are built by
# default; the examples and the test suite (CppUnit) are not.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D WITH_ZLIB=ON \
        -D BUILD_TESTING=OFF \
        -D BUILD_EXAMPLES=OFF \
        ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
