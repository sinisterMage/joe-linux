build() {
    mkdir build
    cd build
    # The X11 pieces are built: the page requires the Xorg libraries, and
    # libx11, libxtst and libxi are what the build asks for. joe Linux has
    # dbus-daemon and no dbus-broker; naming the daemon keeps the launcher
    # from depending on what the build root happens to hold.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gtk2_atk_adaptor=false \
        -D x11=enabled \
        -D introspection=enabled \
        -D default_bus=dbus-daemon \
        -D dbus_daemon=/usr/bin/dbus-daemon \
        -D use_systemd=true \
        -D dbus_glib=disabled \
        -D docs=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
