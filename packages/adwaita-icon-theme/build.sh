prepare() {
    # The last statements of meson.build look for gtk4-update-icon-cache or
    # gtk-update-icon-cache and register it as an install script, which is
    # skipped under DESTDIR anyway. That is the only thing here that needs
    # GTK, while gtk3 and gtk4 need this theme at run time: dropping the
    # lookup breaks the cycle. The cache is rebuilt by gtk3's trigger.
    sed -i '/^gtk_update_icon_cache = find_program(/,$d' meson.build
}

build() {
    mkdir build
    cd build
    meson setup --prefix=/usr ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
