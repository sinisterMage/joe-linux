# Not in the book: the newest upstream release, built as its readme.md says.
# A library only: nothing is preloaded globally. Programs link it, or a user
# runs one with LD_PRELOAD=/usr/lib/libmimalloc.so.
build() {
    # Only the shared library (no static library, no object file, no
    # tests), with its headers and CMake files directly under /usr rather
    # than in versioned mimalloc-3.6 directories. MI_OPT_ARCH=OFF keeps it
    # free of -march=haswell; it is upstream's default on x86_64.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D MI_BUILD_SHARED=ON \
        -D MI_BUILD_STATIC=OFF \
        -D MI_BUILD_OBJECT=OFF \
        -D MI_BUILD_TESTS=OFF \
        -D MI_INSTALL_TOPLEVEL=ON \
        -D MI_OPT_ARCH=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
