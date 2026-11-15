# Not in the book: the newest upstream release. Upstream supports both
# CMake and Meson; Meson is used so that CMake itself could one day build
# against this library without a dependency cycle. The Meson build also
# installs the pkg-config and CMake package files. Upstream publishes no
# checksum for the archive.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --default-library=shared \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
