# Not in the book: the newest upstream release, built as its INSTALL says
# (the release tarball carries a generated configure).
build() {
    # The build generates udev rules and hardware database entries from
    # its device list (util/mtp-hotplug). They mark media players
    # (ID_MEDIA_PLAYER, so that systemd gives the logged-in user access) and
    # run mtp-probe, installed in /usr/lib/udev, on devices it does not know.
    # The API documentation (Doxygen) is not built.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-rpath \
        --disable-doxygen \
        --enable-mtpz \
        --with-udev=/usr/lib/udev
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
