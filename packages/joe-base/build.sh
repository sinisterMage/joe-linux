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
L /var/mail - - - - spool/mail
d /var/tmp 1777 root root 30d
L /var/run - - - - ../run
L /var/lock - - - - ../run/lock
EOT

    # A disk larger than the image that was written to it (a bigger virtual
    # disk, later a real one): systemd-repart extends the root partition over
    # the free space at each boot, and the file system then follows it.
    # Nothing happens when there is no free space.
    install -d "$DESTDIR/usr/lib/repart.d" "$DESTDIR/usr/lib/systemd/system/local-fs.target.wants"
    cat > "$DESTDIR/usr/lib/repart.d/50-root.conf" <<'EOT'
[Partition]
Type=root
EOT
    ln -s ../systemd-growfs-root.service \
        "$DESTDIR/usr/lib/systemd/system/local-fs.target.wants/systemd-growfs-root.service"

    # joe boots without an initramfs, so the kernel mounts the root itself,
    # and until udev has seen the partition btrfs names the device /dev/root,
    # which nothing can open. Both units must wait for udev or they fail.
    local unit
    for unit in systemd-repart systemd-growfs-root; do
        install -d "$DESTDIR/usr/lib/systemd/system/$unit.service.d"
        cat > "$DESTDIR/usr/lib/systemd/system/$unit.service.d/10-joe-root-device.conf" <<'EOT'
[Unit]
After=systemd-udevd.service systemd-udev-trigger.service

[Service]
ExecStartPre=-/usr/bin/udevadm settle --timeout=30
EOT
    done

    # systemd otherwise presets every unmentioned unit on first boot, including
    # optional servers. Keep upstream's earlier core presets and our packaged
    # .wants/aliases; everything else requires an administrator's explicit enable.
    install -d "$DESTDIR/usr/lib/systemd/system-preset" \
        "$DESTDIR/usr/lib/systemd/user-preset"
    cat > "$DESTDIR/usr/lib/systemd/system-preset/99-joe-default.preset" <<'EOT'
# The base system provides SSH access; optional servers remain opt-in.
enable sshd.service
disable *
EOT
    cat > "$DESTDIR/usr/lib/systemd/user-preset/99-joe-default.preset" <<'EOT'
disable *
EOT
}
