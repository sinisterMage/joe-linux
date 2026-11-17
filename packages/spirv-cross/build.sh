# Not in the book: the newest upstream release, built with CMake as the
# README describes, configured as distributions configure it:
# - SPIRV_CROSS_SHARED: the C API as one shared library,
#   libspirv-cross-c-shared.so (what libplacebo and most programs use);
# - SPIRV_CROSS_STATIC stays on: upstream's C++ API exists only as static
#   libraries (libspirv-cross-core.a and friends, with CMake package files),
#   and the spirv-cross program needs them; FORCE_PIC lets them be linked
#   into shared objects.
# The test suite (which needs glslang and SPIRV-Tools sources) is off.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D SPIRV_CROSS_SHARED=ON \
        -D SPIRV_CROSS_STATIC=ON \
        -D SPIRV_CROSS_FORCE_PIC=ON \
        -D SPIRV_CROSS_CLI=ON \
        -D SPIRV_CROSS_ENABLE_TESTS=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
