# Not in the book: the newest upstream release (1.2.6, still current),
# built as its README says. CMAKE_POLICY_VERSION_MINIMUM: the project asks
# for CMake 2.8.12, which CMake 4 refuses. The static library is not built;
# glibc's sys/queue.h is used, not the bundled copy.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_STATIC_LIBS=OFF \
        -D ENABLE_TESTS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
