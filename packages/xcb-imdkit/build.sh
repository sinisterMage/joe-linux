# Not in the book: the newest upstream release, built as its README says.
build() {
    # uthash, a header-only library that has no recipe, is the copy in the
    # source tree.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D USE_SYSTEM_UTHASH=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
