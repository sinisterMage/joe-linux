build() {
    # The book's switches. Stated besides: the unit, udev and D-Bus
    # directories; the manual pages, made with docutils' rst2man; the OBEX
    # daemon (libical) and the CUPS backend, which links no CUPS library and
    # goes to /usr/lib/cups/backend. Left at upstream's defaults (off):
    # Bluetooth mesh, MIDI, the deprecated hci* tools and the test scripts.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --enable-library \
        --enable-systemd \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-systemduserunitdir=/usr/lib/systemd/user \
        --enable-udev \
        --with-udevdir=/usr/lib/udev \
        --enable-obex \
        --enable-cups \
        --enable-manpages \
        --disable-mesh \
        --disable-midi \
        --disable-deprecated \
        --disable-test
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # The book links into an existing /usr/sbin; here it has to be made
    # first, or the link would become usr/sbin itself.
    install -d "$DESTDIR/usr/sbin"
    ln -svf ../libexec/bluetooth/bluetoothd "$DESTDIR/usr/sbin/bluetoothd"

    # make install links dbus-org.bluez.obex.service to obex.service, which
    # is what enabling it does. Nothing is enabled here: joe-desktop
    # enables Bluetooth.
    rm "$DESTDIR/usr/lib/systemd/user/dbus-org.bluez.obex.service"

    install -v -dm555 "$DESTDIR/etc/bluetooth"
    install -v -m644 src/main.conf "$DESTDIR/etc/bluetooth/main.conf"

    cat > "$DESTDIR/etc/bluetooth/rfcomm.conf" << "EOF"
# Start rfcomm.conf
# Set up the RFCOMM configuration of the Bluetooth subsystem in the Linux kernel.
# Use one line per command
# See the rfcomm man page for options


# End of rfcomm.conf
EOF

    cat > "$DESTDIR/etc/bluetooth/uart.conf" << "EOF"
# Start uart.conf
# Attach serial devices via UART HCI to BlueZ stack
# Use one line per device
# See the hciattach man page for options

# End of uart.conf
EOF
}
