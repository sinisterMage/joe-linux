build() {
    mkdir build
    cd build
    # The book's options, plus CMAKE_INSTALL_LIBDIR so that nothing can pick
    # lib64. Abseil's own tests (ABSL_BUILD_TESTING) are off by default.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D ABSL_PROPAGATE_CXX_STD=ON \
        -D BUILD_SHARED_LIBS=ON \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
