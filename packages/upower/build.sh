build() {
    mkdir build
    cd build
    # libimobiledevice does not exist; the installed tests need
    # python-dbusmock and umockdev.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D os_backend=linux \
        -D gtk-doc=false \
        -D man=false \
        -D introspection=enabled \
        -D polkit=enabled \
        -D idevice=disabled \
        -D installed_tests=false \
        -D zshcompletiondir=no
    ninja
}

package() {
    cd build
    # /var/lib/upower is made by the unit's StateDirectory=.
    DESTDIR="$DESTDIR" ninja install
}
