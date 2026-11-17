# Not in the book: the newest upstream release, built with CMake as its
# README describes. Every archive format is built in (upstream's default).
# Shared library only; test_physfs (an interactive test shell) and the
# Doxygen documentation are not built. The CMake files declare a minimum
# version CMake 4 no longer accepts, hence CMAKE_POLICY_VERSION_MINIMUM.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -D PHYSFS_BUILD_SHARED=ON \
        -D PHYSFS_BUILD_STATIC=OFF \
        -D PHYSFS_BUILD_TEST=OFF \
        -D PHYSFS_BUILD_DOCS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
