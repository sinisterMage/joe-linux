# There is no book page. A system installation: the extension and its
# desktop program under /usr/share/gnome-shell/extensions/ding@rastersoft.com,
# its schema under /usr/share/glib-2.0/schemas for glib's trigger. Upstream
# skips compiling schemas itself when DESTDIR is set.
build() {
    meson setup build --prefix=/usr --buildtype=release
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
    # meson also installs an AppArmor profile, and joe has no AppArmor.
    rm -r "${DESTDIR:?}/etc/apparmor.d"
    rmdir "${DESTDIR:?}/etc"
}
