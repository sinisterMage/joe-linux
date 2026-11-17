# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # vnstati (PNG images) needs libgd, which joe does not package.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-image-output
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # make install writes /etc/vnstat.conf with the freshly built vnstat
    # --showconfig, which reads the build root's /etc/vnstat.conf when there
    # is one. Upstream's default file is the same configuration; install it
    # so that the result does not depend on the build root.
    install -m644 cfg/vnstat.conf "$DESTDIR/etc/vnstat.conf"
    # vnstati is not built, but its manual page is installed regardless.
    rm "$DESTDIR/usr/share/man/man1/vnstati.1"

    # The account vnstatd runs as, and its database directory, which the
    # vnstat command reads.
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/vnstat.conf" << "EOF2"
g vnstat 92
u vnstat 92:92 "vnStat network traffic monitor" /var/lib/vnstat /usr/bin/false
EOF2
    cat > "$DESTDIR/usr/lib/tmpfiles.d/vnstat.conf" << "EOF2"
d /var/lib/vnstat 0755 vnstat vnstat -
EOF2

    # Upstream's hardened unit (examples/systemd), run as the vnstat account
    # instead of root; vnstatd needs no privilege to read the interface
    # counters. Not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    sed -e '/^\[Service\]$/a User=vnstat\nGroup=vnstat' \
        -e 's|^ExecReload=/bin/kill|ExecReload=/usr/bin/kill|' \
        examples/systemd/vnstat.service > "$DESTDIR/usr/lib/systemd/system/vnstat.service"
    grep -q '^User=vnstat$' "$DESTDIR/usr/lib/systemd/system/vnstat.service"
}
