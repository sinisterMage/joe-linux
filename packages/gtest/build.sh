# Not in the book: the newest upstream release, built with CMake as
# googletest/README.md describes.
build() {
    # Shared libgtest, libgtest_main, libgmock and libgmock_main. Abseil
    # and RE2 flag and regular expression support stays off, as upstream's
    # default.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_GMOCK=ON \
        -D INSTALL_GTEST=ON \
        -D GTEST_HAS_ABSL=OFF \
        -D gtest_build_tests=OFF \
        -D gtest_build_samples=OFF \
        -D gmock_build_tests=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
