build() {
    mkdir build
    cd build
    # SIMDUTF_TESTS: the test programs are not run, so they are not built.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D SIMDUTF_CXX_STANDARD=20 \
        -D SIMDUTF_TESTS=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
