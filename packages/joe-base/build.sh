package() {
    # Wired networking works without configuration.
    install -d "$DESTDIR/usr/lib/systemd/network"
    cat > "$DESTDIR/usr/lib/systemd/network/80-joe-wired.network" <<'EOT'
[Match]
Type=ether
Kind=!*

[Network]
DHCP=yes
EOT

    # Directories under the shared /var that programs expect to find. The
    # journal directory makes logs persistent, so a failed boot can be examined
    # from the system that replaced it.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/joe-base.conf" <<'EOT'
d /var/lib 0755 root root -
d /var/cache 0755 root root -
d /var/log 0755 root root -
d /var/log/journal 2755 root systemd-journal -
d /var/spool 0755 root root -
d /var/spool/mail 1777 root root -
d /var/tmp 1777 root root 30d
L /var/run - - - - ../run
L /var/lock - - - - ../run/lock
EOT
}
