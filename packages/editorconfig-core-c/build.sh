build() {
    mkdir build
    cd build
    # The book's options; CMAKE_INSTALL_LIBDIR so that nothing can pick
    # lib64. The documentation needs Doxygen.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_DOCUMENTATION=OFF \
        ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
    rm -fv "$DESTDIR/usr/lib/libeditorconfig_static.a"
}
