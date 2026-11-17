# Not in the book: the newest upstream release, built with meson (it has
# no options).
#
# It installs an autostart entry (/etc/xdg/autostart, copied to
# usr/share/applications by upstream's install script) and a systemd user
# unit with no [Install] section; neither needs enabling.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
