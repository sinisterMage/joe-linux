# Not in the book: upstream's release, built with meson. NetworkManager and
# libnma read it to offer the right settings for a SIM's provider.
build() {
    meson setup build --prefix=/usr --buildtype=release
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
