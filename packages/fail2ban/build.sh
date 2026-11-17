# Not in the book: the newest upstream release, built as a wheel (as Arch
# Linux builds it) from upstream's setup.py.
prepare() {
    # The jails' defaults come from a per-distribution paths file;
    # upstream's jail.conf names paths-debian.conf. joe logs to the journal
    # only, like Arch Linux, so paths-arch.conf is the right base (the
    # systemd back end for every service that logs through syslog, Apache's
    # logs in /var/log/httpd). On top of it, as in paths-debian.conf, the
    # nftables actions ban.
    cat > config/paths-joe.conf << "EOF2"
# joe Linux

[INCLUDES]

before = paths-arch.conf

after  = paths-overrides.local


[DEFAULT]

banaction = nftables
banaction_allports = nftables[type=allports]
EOF2
    sed -i 's/^before = paths-debian.conf$/before = paths-joe.conf/' config/jail.conf
    grep -qx 'before = paths-joe.conf' config/jail.conf
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist fail2ban

    # setup.py gives its configuration (and documentation) absolute paths,
    # which a wheel installs under site-packages; move them where they
    # belong. The empty fail2ban.d and jail.d directories are not in the
    # wheel at all.
    local site
    site=$DESTDIR$(python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))')
    mv "$site/etc" "$DESTDIR/etc"
    rm -r "$site/usr"
    install -d "$DESTDIR/etc/fail2ban/fail2ban.d" "$DESTDIR/etc/fail2ban/jail.d"

    # fail2ban-python is a link to the interpreter fail2ban was installed
    # for (the example ignorecommand filter uses it).
    ln -sfn python3 "$DESTDIR/usr/bin/fail2ban-python"

    # Upstream's units, with the programs' directory filled in, and its
    # logrotate configuration for /var/log/fail2ban.log (fail2ban.conf's
    # logtarget). Neither unit is enabled. The service makes /run/fail2ban
    # and /var/lib/fail2ban itself (RuntimeDirectory, StateDirectory).
    install -d "$DESTDIR/usr/lib/systemd/system"
    sed 's|@BINDIR@|/usr/bin|g' files/fail2ban.service.in > "$DESTDIR/usr/lib/systemd/system/fail2ban.service"
    sed 's|@BINDIR@|/usr/bin|g' files/fail2ban.socket.in > "$DESTDIR/usr/lib/systemd/system/fail2ban.socket"
    install -Dm644 files/fail2ban-logrotate "$DESTDIR/etc/logrotate.d/fail2ban"
    install -Dm644 files/bash-completion "$DESTDIR/usr/share/bash-completion/completions/fail2ban"

    install -d "$DESTDIR/usr/share/man/man1" "$DESTDIR/usr/share/man/man5"
    install -m644 man/*.1 "$DESTDIR/usr/share/man/man1/"
    install -m644 man/*.5 "$DESTDIR/usr/share/man/man5/"
}
