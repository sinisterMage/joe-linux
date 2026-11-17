# Not in the book: the newest upstream release, built with CMake as its
# README says. Encryption uses OpenSSL's EVP interface (upstream's default).
# The shared library and the tools (srt-live-transmit, srt-file-transmit,
# srt-tunnel, srt-ffplay) are installed; no static library, no tests.
# Connection bonding stays off, as upstream ships it.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_SHARED=ON \
        -D ENABLE_STATIC=OFF \
        -D ENABLE_APPS=ON \
        -D ENABLE_TESTING=OFF \
        -D ENABLE_UNITTESTS=OFF \
        -D ENABLE_EXAMPLES=OFF \
        -D ENABLE_BONDING=OFF \
        -D ENABLE_ENCRYPTION=ON \
        -D USE_ENCLIB=openssl-evp
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
