# Not in the book: the newest upstream release, built as its README says
# ("make install", the systemd variant).
build() {
    make
}

package() {
    # Upstream's paths, except that units go in /usr/lib/systemd/system.
    # Installs atop, atopsar, atopconvert, atopcat, atophide and atopacctd,
    # and the units: atop.service (writes a raw log in /var/log/atop every
    # ten minutes), atopacct.service (atopacctd, process accounting),
    # atop-rotate.timer (restarts atop daily for a new log). None is
    # enabled; the Makefile enables them only when installing without
    # DESTDIR.
    make DESTDIR="$DESTDIR" \
        SBINPATH=/usr/sbin \
        SYSDPATH=/usr/lib/systemd/system \
        PMPATHD=/usr/lib/systemd/system-sleep \
        install

    # atopgpud, the GPU statistics daemon, is a Python program built on
    # NVIDIA's pynvml (nvidia-ml-py), which has no recipe; it is left out
    # with its unit and manual page.
    rm "$DESTDIR/usr/sbin/atopgpud" \
        "$DESTDIR/usr/lib/systemd/system/atopgpu.service" \
        "$DESTDIR/usr/share/man/man8/atopgpud.8"

    # make install creates /etc/default/atop empty; atop.service reads it.
    # Upstream's own package ships atop.default there, the same defaults the
    # unit sets.
    install -m644 atop.default "$DESTDIR/etc/default/atop"

    # atop-pm.sh stops atop before suspend and starts it on resume, which
    # would start it after the first suspend even though it is not enabled.
    # It is started again only when enabled.
    grep -q '^	post)	/usr/bin/systemctl start atop$' "$DESTDIR/usr/lib/systemd/system-sleep/atop-pm.sh"
    sed -i 's|^	post)	/usr/bin/systemctl start atop$|	post)	/usr/bin/systemctl -q is-enabled atop \&\& /usr/bin/systemctl start atop|' \
        "$DESTDIR/usr/lib/systemd/system-sleep/atop-pm.sh"

    # The log directory (/var is not packaged).
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/atop.conf" << "EOF"
d /var/log/atop 0755 root root -
EOF
}
