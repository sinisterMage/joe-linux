# Not in the book: the newest upstream release, built as its README says.
build() {
    # The configuration is /etc/ddclient/ddclient.conf, the state of the
    # last updates /var/cache/ddclient/ddclient.cache.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --runstatedir=/run \
        --with-curl=/usr/bin/curl
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The configuration holds the providers' passwords; ddclient insists
    # that only its owner can read it.
    chmod 600 "$DESTDIR/etc/ddclient/ddclient.conf"

    # Upstream's sample unit: ddclient in the foreground, checking every
    # five minutes. Not enabled.
    install -Dm644 sample-etc_systemd.service "$DESTDIR/usr/lib/systemd/system/ddclient.service"

    # The cache directory make install creates under /var.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/ddclient.conf" << "EOF2"
d /var/cache/ddclient 0700 root root -
EOF2
}
