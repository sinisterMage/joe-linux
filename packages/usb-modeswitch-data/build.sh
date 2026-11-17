# Not in the book: the newest upstream release, built as its README says.
# The rules file ships generated (gen-rules.tcl is not run).
package() {
    # One configuration file per device in /usr/share/usb_modeswitch; the
    # rules in /usr/lib/udev/rules.d, not /lib/udev/rules.d. Local
    # additions go in /etc/usb_modeswitch.d.
    make DESTDIR="$DESTDIR" RULESDIR="$DESTDIR/usr/lib/udev/rules.d" install
}
