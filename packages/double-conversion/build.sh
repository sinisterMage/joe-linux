build() {
    mkdir build
    cd build
    # The book's options, without the tests.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_TESTING=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
