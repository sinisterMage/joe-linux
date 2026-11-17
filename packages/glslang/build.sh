# Following the book's glslang page, without its test suite
# (GLSLANG_TESTS). ALLOW_EXTERNAL_SPIRV_TOOLS: SPIRV-Tools is joe's
# spirv-tools package rather than a copy in External/.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ALLOW_EXTERNAL_SPIRV_TOOLS=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D GLSLANG_TESTS=OFF \
        -D BUILD_EXTERNAL=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
