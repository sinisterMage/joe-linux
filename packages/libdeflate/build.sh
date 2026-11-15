# Not in the book: the newest upstream release, built with CMake as its
# README describes.
build() {
    mkdir build
    cd build
    # The shared library only, and the libdeflate-gzip program (with
    # libdeflate-gunzip) linked against it.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D LIBDEFLATE_BUILD_STATIC_LIB=OFF \
        -D LIBDEFLATE_BUILD_SHARED_LIB=ON \
        -D LIBDEFLATE_USE_SHARED_LIB=ON \
        -D LIBDEFLATE_BUILD_GZIP=ON \
        -D LIBDEFLATE_BUILD_TESTS=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
