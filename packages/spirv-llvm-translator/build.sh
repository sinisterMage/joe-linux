build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D LLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR=/usr \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
