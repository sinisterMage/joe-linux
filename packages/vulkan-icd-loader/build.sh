# Following the book's Vulkan-Loader page, under the name distributions
# give the package (vulkan-icd-loader). CMAKE_INSTALL_LIBDIR so that
# GNUInstallDirs cannot pick lib64. Window-system support: X11 (xcb, Xlib,
# Xrandr) and Wayland, upstream's defaults; DirectFB stays off.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_TESTS=OFF \
        -D BUILD_WSI_XCB_SUPPORT=ON \
        -D BUILD_WSI_XLIB_SUPPORT=ON \
        -D BUILD_WSI_XLIB_XRANDR_SUPPORT=ON \
        -D BUILD_WSI_WAYLAND_SUPPORT=ON \
        -D BUILD_WSI_DIRECTFB_SUPPORT=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
