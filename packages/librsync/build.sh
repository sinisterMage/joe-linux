# Not in the book: the newest upstream release, built as its doc/install.md
# says.
build() {
    mkdir build
    cd build
    # rdiff is built (popt). BLAKE2 is upstream's bundled reference code
    # (USE_LIBB2 is off by default, and libb2 is not packaged). Compression
    # stays off: upstream says it does not work yet, and bzip2 and zlib are
    # only linked with it.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_RDIFF=ON \
        -D USE_LIBB2=OFF \
        -D ENABLE_COMPRESSION=OFF \
        -D ENABLE_TRACE=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
