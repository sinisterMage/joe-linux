# Not in the book: the newest upstream release, built as its README says.

prepare() {
    # joe's own changes, which upstream does not have:
    # - count the packages dave has installed (one directory each under
    #   /usr/lib/dave/db), shown as "N (dave)";
    # - joe Linux's logo, a packet of instant coffee, chosen for ID=joe in
    #   /etc/os-release.
    patch -Np1 -i /recipe/joe-dave-packages.patch
    patch -Np1 -i /recipe/joe-logo.patch
}

build() {
    # Switched off because joe Linux has no recipe for what they need:
    # Vulkan (vulkan-headers), OpenCL, VDPAU, EET, RPM, ZFS, ImageMagick and
    # chafa (image logos). The embedded yyjson is used, since there is no
    # system one. flashfetch is upstream's small example program.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_SYSCONFDIR=/etc \
        -D CMAKE_BUILD_TYPE=Release \
        -D BINARY_LINK_TYPE=dlopen \
        -D SET_TWEAK=OFF \
        -D BUILD_TESTS=OFF \
        -D BUILD_FLASHFETCH=OFF \
        -D ENABLE_SYSTEM_YYJSON=OFF \
        -D ENABLE_VULKAN=OFF \
        -D ENABLE_OPENCL=OFF \
        -D ENABLE_VDPAU=OFF \
        -D ENABLE_EET=OFF \
        -D ENABLE_RPM=OFF \
        -D ENABLE_LIBZFS=OFF \
        -D ENABLE_IMAGEMAGICK6=OFF \
        -D ENABLE_IMAGEMAGICK7=OFF \
        -D ENABLE_CHAFA=OFF \
        -D ENABLE_WAYLAND=ON \
        -D ENABLE_XCB_RANDR=ON \
        -D ENABLE_XRANDR=ON \
        -D ENABLE_DRM=ON \
        -D ENABLE_VADRM=ON \
        -D ENABLE_VAX11=ON \
        -D ENABLE_GIO=ON \
        -D ENABLE_DCONF=ON \
        -D ENABLE_DBUS=ON \
        -D ENABLE_SQLITE3=ON \
        -D ENABLE_EGL=ON \
        -D ENABLE_GLX=ON \
        -D ENABLE_ELF=ON \
        -D ENABLE_ZLIB=ON \
        -D ENABLE_LUA=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
