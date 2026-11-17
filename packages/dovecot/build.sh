# Following the book's Dovecot page.
build() {
    # The book's flags, with the run-time directory in /run. Added, from
    # the optional dependencies that have recipes: GSSAPI, LDAP and the SQL
    # driver for SQLite as plugins, Lua, Solr full-text search, libsodium,
    # ICU, PCRE2, libunwind, libcap and the compressors. Off: the MySQL
    # and PostgreSQL drivers (those packages carry their servers),
    # Cassandra, CDB, Xapian (flatcurve), libstemmer, libtextcat,
    # AppArmor and libbsd, which have no recipes.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-rundir=/run/dovecot \
        --docdir=/usr/share/doc/dovecot-2.4.5 \
        --disable-static \
        --with-pam \
        --with-gssapi=plugin \
        --with-ldap=plugin \
        --with-sql=plugin \
        --with-sqlite \
        --without-pgsql \
        --without-mysql \
        --without-cassandra \
        --without-cdb \
        --with-lua=plugin \
        --with-solr \
        --without-flatcurve \
        --without-stemmer \
        --without-textcat \
        --with-icu \
        --with-pcre2 \
        --with-sodium \
        --with-bzlib \
        --with-lz4 \
        --with-zstd \
        --with-libcap \
        --with-libunwind \
        --with-systemd \
        --without-apparmor \
        --without-libbsd \
        CXX="g++ -std=gnu++17"
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The book's configuration: IMAP only, without TLS until certificates
    # are configured, mbox mail in /var/mail and ~/Mail, system users
    # through PAM.
    mv "$DESTDIR/etc/dovecot/dovecot.conf" "$DESTDIR/etc/dovecot/dovecot.conf.orig"
    cat > "$DESTDIR/etc/dovecot/dovecot.conf" << "EOT"

# The dovecot configuration requires a minimum version to be set. The server
# will refuse to start if the version set here is older than the version of
# Dovecot installed. This option allows the Dovecot server to set reasonable
# default values based on what version is set here.
dovecot_config_version = 2.4.5

# This option sets the minimum version that is able to read data files from
# the Dovecot server. This is primarily for a cluster which may have several
# different versions of Dovecot installed, but is required for the server to
# run.
dovecot_storage_version = 2.4.5

protocols = imap
ssl = no
# The next line is only needed if you have no IPv6 network interfaces
listen = *
mail_inbox_path = /var/mail/%{user}
mail_driver = mbox
mail_path = ~/Mail
userdb users {
  driver = passwd
}
passdb passwords {
  driver = pam
}
EOT
    install -d "$DESTDIR/etc/pam.d"
    cat > "$DESTDIR/etc/pam.d/dovecot" << "EOT"
# Begin /etc/pam.d/dovecot

auth     include system-auth
account  include system-account
password include system-password

# End /etc/pam.d/dovecot
EOT

    # The accounts the book creates (dovecot 42, dovenull 43).
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/dovecot.conf" << "EOT"
g dovecot 42
u dovecot 42:42 "Dovecot unprivileged user" /dev/null /usr/bin/false
g dovenull 43
u dovenull 43:43 "Dovecot login user" /dev/null /usr/bin/false
EOT
    # Dovecot's state directory. /var/mail (the book's chmod 1777) is
    # joe-base's, a link to the sticky, world-writable /var/spool/mail.
    # Dovecot makes /run/dovecot itself.
    cat > "$DESTDIR/usr/lib/tmpfiles.d/dovecot.conf" << "EOT"
d /var/lib/dovecot 0755 root root -
EOT
    # make install puts upstream's dovecot.service and dovecot.socket in
    # /usr/lib/systemd/system; neither is enabled.
}
