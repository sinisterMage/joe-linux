# There is no book page. Installs the themes adw-gtk3 and adw-gtk3-dark
# under /usr/share/themes, for GTK 3; libadwaita applications already look
# this way. joe-desktop selects it.
build() {
    meson setup build --prefix=/usr --buildtype=release
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
