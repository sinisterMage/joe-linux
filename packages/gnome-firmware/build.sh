# Not in the book: the newest upstream release, built with meson as its
# README.md says.
build() {
    mkdir build
    cd build
    # --wrap-mode=nodownload: fwupd, libxmlb, libadwaita, libjcat and gcab
    # are named as subprojects to fetch when missing. Rebooting after an
    # update goes through logind; ConsoleKit is not used on joe.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D systemd=true \
        -D elogind=false \
        -D consolekit=false \
        -D man=true \
        -D devel=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
