build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
