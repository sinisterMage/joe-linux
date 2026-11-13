build() {
    mkdir -p build
    cd build
    # No debug-gui (the event viewer needs GTK), no tests (they need check and
    # are not run) and no documentation (it needs doxygen and sphinx). libwacom
    # is used for tablets (the book builds without it), Lua 5.4 for plugins;
    # plugins are only loaded when the compositor asks for them. The udev rules
    # and their helper programs go to /usr/lib/udev.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D debug-gui=false \
        -D tests=false \
        -D documentation=false \
        -D libwacom=true \
        -D mtdev=true \
        -D lua-plugins=enabled \
        -D udev-dir=/usr/lib/udev
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
