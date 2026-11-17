# Not in the book: the newest upstream release, built with CMake as its
# documentation (docs/compile.md) describes: a shared library with both
# the Wayland and the X11 back ends. The examples, tests and the Doxygen
# documentation are off.
unpack() {
    # The release archive is a zip file, which GNU tar cannot read.
    bsdtar -xf "$SOURCES/$PKG_SOURCE" --strip-components=1 --no-same-owner --no-same-permissions
}

build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D GLFW_BUILD_WAYLAND=ON \
        -D GLFW_BUILD_X11=ON \
        -D GLFW_BUILD_EXAMPLES=OFF \
        -D GLFW_BUILD_TESTS=OFF \
        -D GLFW_BUILD_DOCS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
