build() {
    mkdir -p build
    cd build
    # The tests need pytest, python-libevdev and pyudev; the documentation needs
    # doxygen. Installs udev rules and a hwdb file under /usr/lib/udev.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D tests=disabled \
        -D documentation=disabled \
        -D udev-dir=/usr/lib/udev
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
