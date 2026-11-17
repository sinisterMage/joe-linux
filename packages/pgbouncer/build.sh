# Not in the book: the newest upstream release, built with its Autoconf
# build, which its README recommends for packaging.
build() {
    # TLS (OpenSSL), DNS through c-ares (upstream's preferred backend), PAM
    # and LDAP (auth_type = ldap, OpenLDAP) authentication, and systemd
    # notification (Type=notify). The root certificates are those make-ca
    # keeps, named rather than probed for.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-openssl \
        --with-root-ca-file=/etc/pki/tls/certs/ca-bundle.crt \
        --with-cares \
        --with-pam \
        --with-ldap \
        --with-systemd
    # The manual pages are made from doc/*.md with pandoc, which joe Linux
    # does not have, and the release tarball carries none. They are part of
    # "all" and "install", so the list is emptied on both command lines.
    make dist_man_MANS=
}

package() {
    make DESTDIR="$DESTDIR" dist_man_MANS= install

    # Upstream's sample configuration, with the pid file and the Unix
    # socket in /run/pgbouncer, which pgbouncer may write to. Clients reach
    # the socket with -h /run/pgbouncer -p 6432 (libpq's default directory,
    # /run/postgresql, belongs to the postgres account). The databases to
    # pool and auth_file (/etc/pgbouncer/userlist.txt) are left to the
    # administrator.
    install -d "$DESTDIR/etc/pgbouncer"
    sed -e 's@^pidfile = .*@pidfile = /run/pgbouncer/pgbouncer.pid@' \
        -e 's@^;unix_socket_dir = /tmp@unix_socket_dir = /run/pgbouncer@' \
        etc/pgbouncer.ini > "$DESTDIR/etc/pgbouncer/pgbouncer.ini"
    chmod 644 "$DESTDIR/etc/pgbouncer/pgbouncer.ini"

    # The account pgbouncer runs as, its log directory and its run-time
    # directory (/var and /run are not packaged).
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/pgbouncer.conf" << "EOF2"
g pgbouncer 47
u pgbouncer 47:47 "PgBouncer connection pooler" - /usr/bin/false
EOF2
    cat > "$DESTDIR/usr/lib/tmpfiles.d/pgbouncer.conf" << "EOF2"
d /var/log/pgbouncer 0750 pgbouncer pgbouncer -
d /run/pgbouncer 0755 pgbouncer pgbouncer -
EOF2

    # Upstream's unit (etc/pgbouncer.service), running as the pgbouncer
    # account instead of postgres. It is not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/pgbouncer.service" << "EOF2"
[Unit]
Description=connection pooler for PostgreSQL
Documentation=https://www.pgbouncer.org/
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=pgbouncer
Group=pgbouncer
ExecStart=/usr/bin/pgbouncer /etc/pgbouncer/pgbouncer.ini
ExecReload=/usr/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF2
}
