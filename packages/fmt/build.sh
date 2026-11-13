build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=/usr/lib \
        -D BUILD_SHARED_LIBS=ON \
        -D FMT_TEST=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
