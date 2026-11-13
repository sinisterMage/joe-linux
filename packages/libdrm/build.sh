build() {
    mkdir -p build
    cd build
    # udev=true: wait for udev (systemd) to create the device nodes instead of
    # calling mknod. intel=enabled: libdrm_intel, which needs libpciaccess, is
    # built or the build fails, instead of depending on what is installed.
    # No valgrind. cairo is only used by the test programs, which are not built.
    # The manual pages (rst2man, from docutils) are left out.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D udev=true \
        -D valgrind=disabled \
        -D intel=enabled \
        -D cairo-tests=disabled \
        -D man-pages=disabled \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
