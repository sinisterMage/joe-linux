# Not in the book: the newest upstream release, built as its INSTALL and
# README.packaging say (the release tarball carries a generated configure).
build() {
    # The standard set of camera drivers. Switched off because joe has no
    # recipe for what they need: libgd (image conversion in a few drivers),
    # libusb 0.1 (libusb 1.0 is used), and the lockdev/ttylock serial-port
    # locking libraries.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-rpath \
        --with-camlibs=standard \
        --without-gdlib \
        --without-libusb \
        --disable-lockdev \
        --disable-ttylock \
        udevscriptdir=/usr/lib/udev
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The udev rules and hardware database entries that mark cameras
    # (ID_GPHOTO2, so that systemd gives the logged-in user access), made as
    # README.packaging says: print-camera-list run against the drivers just
    # installed. Version 201 rules carry only the SCSI-tunnelled devices;
    # everything else is in the hardware database.
    local camlibs iolibs
    camlibs=$(echo "$DESTDIR"/usr/lib/libgphoto2/[0-9]*)
    iolibs=$(echo "$DESTDIR"/usr/lib/libgphoto2_port/[0-9]*)
    install -d "$DESTDIR/usr/lib/udev/rules.d" "$DESTDIR/usr/lib/udev/hwdb.d"
    LD_LIBRARY_PATH="$DESTDIR/usr/lib" CAMLIBS="$camlibs" IOLIBS="$iolibs" \
        "$DESTDIR/usr/lib/libgphoto2/print-camera-list" udev-rules version 201 \
        > "$DESTDIR/usr/lib/udev/rules.d/40-libgphoto2.rules"
    LD_LIBRARY_PATH="$DESTDIR/usr/lib" CAMLIBS="$camlibs" IOLIBS="$iolibs" \
        "$DESTDIR/usr/lib/libgphoto2/print-camera-list" hwdb \
        > "$DESTDIR/usr/lib/udev/hwdb.d/20-libgphoto2.hwdb"
    # Fail if the drivers were not found: the database would be empty.
    grep -q ID_GPHOTO2 "$DESTDIR/usr/lib/udev/hwdb.d/20-libgphoto2.hwdb"
}
