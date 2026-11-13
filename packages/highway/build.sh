build() {
    mkdir build
    cd build
    # The book's options; CMAKE_INSTALL_LIBDIR so that nothing can pick
    # lib64, and no example programs.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTING=OFF \
        -D BUILD_SHARED_LIBS=ON \
        -D HWY_ENABLE_EXAMPLES=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
