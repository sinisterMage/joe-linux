# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules, with the renewal timer upstream's
# packaging guide (docs/packaging.rst) asks distributions to provide.
#
# The manual page is not built: upstream makes it with Sphinx and the
# sphinx_rtd_theme extension, which is not packaged, from the text
# "certbot --help all" prints (docs/cli-help.txt).
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist certbot

    # "certbot renew -q" twice a day, at a random time per machine so that
    # clients do not all reach the CA at once, as docs/packaging.rst asks.
    # Not enabled: "systemctl enable --now certbot-renew.timer" turns it on.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/certbot-renew.service" << "EOF2"
[Unit]
Description=Renew certificates obtained with certbot
Documentation=https://eff-certbot.readthedocs.io/
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet
EOF2
    cat > "$DESTDIR/usr/lib/systemd/system/certbot-renew.timer" << "EOF2"
[Unit]
Description=Renew certificates obtained with certbot twice a day

[Timer]
OnCalendar=*-*-* 00,12:00:00
RandomizedDelaySec=12h
Persistent=true

[Install]
WantedBy=timers.target
EOF2
}
