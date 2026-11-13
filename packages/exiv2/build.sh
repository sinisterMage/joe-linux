build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D EXIV2_ENABLE_VIDEO=yes \
        -D EXIV2_ENABLE_WEBREADY=yes \
        -D EXIV2_ENABLE_CURL=yes \
        -D EXIV2_ENABLE_BROTLI=yes \
        -D EXIV2_ENABLE_INIH=yes \
        -D EXIV2_ENABLE_NLS=no \
        -D EXIV2_BUILD_SAMPLES=no \
        -D EXIV2_BUILD_UNIT_TESTS=no \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
