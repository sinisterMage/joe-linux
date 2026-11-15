# Not in the book (Beyond LFS has dropped its page): the newest upstream
# release, built as its BUILDING.md says, with the switches and the
# privilege separation account of the book's last dhcpcd page.
build() {
    # Privilege separation as dhcpcd, seccomp filtering, the udev plugin
    # (dhcpcd waits for udev to finish naming an interface) and OpenSSL's
    # libcrypto for authentication. The kernel's packet filters are used,
    # not libpcap, as upstream recommends.
    #
    # Hooks: upstream's default ones (01-test, 20-resolv.conf, 30-hostname)
    # plus those for NTP servers (chrony) and systemd-timesyncd, named here
    # because configure would otherwise choose them by looking for the
    # daemons in the build root.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --sbindir=/usr/sbin \
        --libexecdir=/usr/lib/dhcpcd \
        --dbdir=/var/lib/dhcpcd \
        --runstatedir=/run \
        --privsepuser=dhcpcd \
        --enable-privsep \
        --enable-seccomp \
        --with-udev \
        --with-openssl \
        --without-libpcap \
        --with-hooks="ntp.conf timesyncd.conf"
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The account and lease directory of the book (groupadd -g 52, useradd
    # -u 52; install -m700 -d /var/lib/dhcpcd, owned by dhcpcd).
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/dhcpcd.conf" << "EOF"
g dhcpcd 52
u dhcpcd 52:52 "dhcpcd PrivSep" /var/lib/dhcpcd /usr/bin/false
EOF
    cat > "$DESTDIR/usr/lib/tmpfiles.d/dhcpcd.conf" << "EOF"
d /var/lib/dhcpcd 0700 dhcpcd dhcpcd -
EOF

    # Upstream ships no units. These are the book's last ones: dhcpcd@NAME
    # for one interface, and dhcpcd.service for all of them. Neither is
    # enabled; NetworkManager has its own DHCP client.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/dhcpcd@.service" << "EOF"
[Unit]
Description=dhcpcd on %I
Wants=network.target
Before=network.target
BindsTo=sys-subsystem-net-devices-%i.device
After=sys-subsystem-net-devices-%i.device

[Service]
Type=forking
PIDFile=/run/dhcpcd/%I.pid
ExecStart=/usr/sbin/dhcpcd -q %I
ExecStop=/usr/sbin/dhcpcd -k %I

[Install]
WantedBy=multi-user.target
EOF
    cat > "$DESTDIR/usr/lib/systemd/system/dhcpcd.service" << "EOF"
[Unit]
Description=dhcpcd on all interfaces
Wants=network.target
Before=network.target

[Service]
Type=forking
PIDFile=/run/dhcpcd/pid
ExecStart=/usr/sbin/dhcpcd -q -b
ExecStop=/usr/sbin/dhcpcd -x

[Install]
WantedBy=multi-user.target
EOF
}
