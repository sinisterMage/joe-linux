prepare() {
    # glibc's C23 strchr returns const char * for a const argument; the
    # gphoto2 backend casts its own writable string to const before writing
    # through the result.
    sed -i "s/\*strchr ((const char \*) folder_list\[n\], ' ') = '\\\\0';/*strchr (folder_list[n], ' ') = '\\\\0';/" \
        backend/gphoto2.c
    grep -q "\*strchr (folder_list\[n\], ' ') = " backend/gphoto2.c
}

build() {
    # The book runs configure as the scanner group (sg scanner) only to give
    # the lock directory that group, which tmpfiles.d does here instead.
    # The book's --with-lockdir=/run/lock would put the device locks
    # (LCK..*) straight into /run/lock, which only root can write, while it
    # goes on to make /run/lock/sane for the scanner group; the locks go to
    # that directory here, as other distributions put them.
    # Stated rather than detected: Avahi, libusb, libcurl, Poppler's GLib
    # binding, USB record/replay (libxml2) and systemd (saned socket
    # activation) are on, with camera and video backends through libgphoto2
    # and v4l-utils. Net-SNMP and libieee1284 remain unavailable.
    PYTHON=python3 ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-lockdir=/run/lock/sane \
        --docdir=/usr/share/doc/sane-backends-1.4.0 \
        --disable-static \
        --with-avahi=yes \
        --with-usb=yes \
        --with-libcurl=yes \
        --with-poppler-glib=yes \
        --with-usb-record-replay=yes \
        --with-systemd=yes \
        --with-snmp=no \
        --with-gphoto2 \
        --with-v4l
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # The book puts the rules in /etc/udev/rules.d; packaged ones belong in
    # /usr/lib/udev/rules.d. They give the scanner group access to every
    # scanner libsane knows and set libsane_matched, which systemd's
    # 70-uaccess.rules turns into access for the logged-in user.
    install -Dm644 tools/udev/libsane.rules \
        "$DESTDIR/usr/lib/udev/rules.d/65-scanner.rules"

    # The book's "groupadd -g 70 scanner", and the lock directory with the
    # group it gives it and the mode "make install" creates it with.
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/sane.conf" << "EOF2"
g scanner 70
EOF2
    cat > "$DESTDIR/usr/lib/tmpfiles.d/sane.conf" << "EOF2"
d /run/lock/sane 0775 root scanner -
EOF2
}
