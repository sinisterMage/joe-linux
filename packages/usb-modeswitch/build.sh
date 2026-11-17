# Not in the book: the newest upstream release, built as its README says,
# with the Tcl script as the dispatcher (jimtcl, which would let it be
# compiled in, is not packaged).
build() {
    # The Makefile adds its warnings to CFLAGS but no optimisation.
    CFLAGS="-O2" make
}

package() {
    # The udev helper (usb_modeswitch, called by the rules) goes to
    # /usr/lib/udev, not /lib/udev.
    make DESTDIR="$DESTDIR" UDEVDIR="$DESTDIR/usr/lib/udev" install

    # make install adds the unit only where /etc/systemd/system exists.
    # udev's helper starts usb_modeswitch@DEVICE.service for each device to
    # switch, so the template needs no enabling.
    install -Dm644 usb_modeswitch@.service "$DESTDIR/usr/lib/systemd/system/usb_modeswitch@.service"

    # The dispatcher records devices it gave a gsmmodem link in
    # /var/lib/usb_modeswitch.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/usb-modeswitch.conf" << "EOF2"
d /var/lib/usb_modeswitch 0755 root root -
EOF2
}
