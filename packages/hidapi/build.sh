# Not in the book: the newest upstream release, built with CMake as its
# BUILD.cmake.md says. Both Linux back ends are built as shared libraries:
# libhidapi-hidraw (the kernel's hidraw devices) and libhidapi-libusb.
# upstream's udev/69-hid.rules is only a template to copy for one device,
# so it is not installed.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D HIDAPI_WITH_HIDRAW=ON \
        -D HIDAPI_WITH_LIBUSB=ON \
        -D HIDAPI_WITH_TESTS=OFF \
        -D HIDAPI_BUILD_HIDTEST=OFF
    cmake --build build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
