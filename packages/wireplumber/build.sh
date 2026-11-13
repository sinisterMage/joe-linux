build() {
    mkdir build
    cd build
    # GObject introspection data is generated from Doxygen output, and
    # Doxygen does not exist; nothing in GNOME uses the typelib.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D system-lua=true \
        -D system-lua-version=auto \
        -D systemd=enabled \
        -D systemd-user-service=true \
        -D systemd-system-service=false \
        -D elogind=disabled \
        -D introspection=disabled \
        -D doc=disabled \
        -D modules=true \
        -D daemon=true \
        -D tools=true \
        -D tests=false \
        -D dbus-tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
