# Not in the book: the newest upstream release, built with meson as its
# README says.
build() {
    mkdir build
    cd build
    # EGL only: QEMU renders headless or through SPICE, never through GLX.
    # Venus (Vulkan) needs the Vulkan loader, which is not packaged, and so
    # does the render server it alone uses. No DRM native contexts: they
    # are experimental or for ARM GPUs.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D platforms=egl \
        -D venus=false \
        -D video=true \
        -D tracing=none \
        -D tests=false \
        -D fuzzer=false \
        -D valgrind=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
