# There is no book page. A system installation: the extension under
# /usr/share/gnome-shell/extensions, its schema under
# /usr/share/glib-2.0/schemas for glib's trigger. Applications that show a
# tray icon (status notifier items) need nothing else.
build() {
    meson setup build --prefix=/usr --buildtype=release -D local_install=disabled
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
    # meson compiles the schemas as it installs, even into DESTDIR. The
    # compiled file is glib's trigger's to make, from every package's
    # schemas; shipped, it would be overwritten and then fail its seal.
    rm "${DESTDIR:?}/usr/share/glib-2.0/schemas/gschemas.compiled"
}
