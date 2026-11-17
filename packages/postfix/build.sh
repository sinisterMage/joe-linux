# Following the book's Postfix page.
prepare() {
    sed -i 's/.\x08//g' README_FILES/*
}

build() {
    # The book's lookup tables and features, chosen here explicitly rather
    # than by testing what the build root holds: Cyrus SASL, LMDB, LDAP,
    # SQLite and TLS. PCRE2 tables and SMTPUTF8 (ICU) are what makedefs
    # finds by itself. Off: NIS (libnsl has no recipe), Berkeley DB, CDB,
    # and the MySQL and PostgreSQL tables (those packages carry their
    # servers, which postfix would then pull in).
    local CCARGS="-DNO_NIS -DNO_DB"
    local AUXLIBS=""
    CCARGS="$CCARGS -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl"
    AUXLIBS="$AUXLIBS -lsasl2"
    CCARGS="$CCARGS -DHAS_LMDB"
    local AUXLIBS_LMDB="-llmdb"
    CCARGS="$CCARGS -DHAS_LDAP"
    AUXLIBS="$AUXLIBS -lldap -llber"
    CCARGS="$CCARGS -DHAS_SQLITE"
    AUXLIBS="$AUXLIBS -lsqlite3 -lpthread"
    CCARGS="$CCARGS -DUSE_TLS -I/usr/include/openssl/"
    AUXLIBS="$AUXLIBS -lssl -lcrypto"

    make makefiles \
        CCARGS="$CCARGS" \
        AUXLIBS="$AUXLIBS" \
        AUXLIBS_LMDB="$AUXLIBS_LMDB" \
        default_database_type=lmdb \
        default_cache_db_type=lmdb
    make
}

package() {
    # install_root stages the files; it also makes postfix-install drop
    # ownership and the set-gid bits, which are restored below.
    sh postfix-install -non-interactive \
        install_root="$DESTDIR" \
        daemon_directory=/usr/lib/postfix \
        manpage_directory=/usr/share/man \
        html_directory=/usr/share/doc/postfix-3.11.7/html \
        readme_directory=/usr/share/doc/postfix-3.11.7/readme

    # postdrop and postqueue are set-gid postdrop (meta/postfix-files:
    # 2755 root:postdrop). Packaged files belong to root, so the group is
    # given at boot by tmpfiles.d below.
    chmod 2755 "$DESTDIR/usr/sbin/postdrop" "$DESTDIR/usr/sbin/postqueue"

    # The book's aliases. Mail for root goes to root until a login is
    # named on the root line.
    cat > "$DESTDIR/etc/aliases" << "EOT"
# Begin /etc/aliases

MAILER-DAEMON:    postmaster
postmaster:       root

#root:             <LOGIN>
# End /etc/aliases
EOT
    cat >> "$DESTDIR/etc/postfix/main.cf" << "EOT"
default_database_type = lmdb
alias_database = lmdb:/etc/aliases
alias_maps = lmdb:/etc/aliases
smtpd_forbid_bare_newline = normalize
smtpd_forbid_bare_newline_exclusions = $mynetworks
EOT

    # The accounts the book creates (groupadd -g 32 postfix, -g 33
    # postdrop; useradd -u 32 -g postfix).
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/postfix.conf" << "EOT"
g postfix 32
g postdrop 33
u postfix 32:32 "Postfix Daemon User" /var/spool/postfix /usr/bin/false
EOT
    # What "postfix set-permissions" would make, from meta/postfix-files:
    # the queue, with maildrop and public writable by the postdrop group,
    # the data directory and the set-gid programs' group. The mail spool
    # local(8) delivers to, /var/mail, is joe-base's: a link to the sticky,
    # world-writable /var/spool/mail, as Dovecot's page wants it (so the
    # book's chown postfix:postfix is not needed).
    cat > "$DESTDIR/usr/lib/tmpfiles.d/postfix.conf" << "EOT"
d /var/lib/postfix 0700 postfix - -
d /var/spool/postfix 0755 root root -
d /var/spool/postfix/active 0700 postfix - -
d /var/spool/postfix/bounce 0700 postfix - -
d /var/spool/postfix/corrupt 0700 postfix - -
d /var/spool/postfix/defer 0700 postfix - -
d /var/spool/postfix/deferred 0700 postfix - -
d /var/spool/postfix/flush 0700 postfix - -
d /var/spool/postfix/hold 0700 postfix - -
d /var/spool/postfix/incoming 0700 postfix - -
d /var/spool/postfix/private 0700 postfix - -
d /var/spool/postfix/maildrop 0730 postfix postdrop -
d /var/spool/postfix/public 0710 postfix postdrop -
d /var/spool/postfix/pid 0755 root root -
d /var/spool/postfix/saved 0700 postfix - -
d /var/spool/postfix/trace 0700 postfix - -
z /usr/sbin/postdrop 2755 root postdrop -
z /usr/sbin/postqueue 2755 root postdrop -
EOT

    # "make install-postfix" from blfs-systemd-units, with the alias
    # database (/etc/aliases.lmdb, made from /etc/aliases by newaliases)
    # rebuilt before each start, since it cannot be packaged. Not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/postfix.service" << "EOT"
[Unit]
Description=Postfix Mail Transport Agent
After=network.target
Conflicts=sendmail.service exim.service

[Service]
Type=forking
PIDFile=/var/spool/postfix/pid/master.pid
ExecStartPre=/usr/bin/newaliases
ExecStart=/usr/sbin/postfix start
ExecStop=/usr/sbin/postfix stop
ExecReload=/usr/sbin/postfix reload
Restart=always

[Install]
WantedBy=multi-user.target
EOT
}
