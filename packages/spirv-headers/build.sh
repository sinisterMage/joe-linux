build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
