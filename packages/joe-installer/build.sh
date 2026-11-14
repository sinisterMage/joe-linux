# The installer is joe's own code, in installer/ of this repository (see its
# README.md). bootstrap/build-packages.sh copies that directory into this
# recipe's files/ before the build.
build() {
    cmake -S /recipe/files/installer -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
