# Following the book's Cyrus SASL page.
prepare() {
    patch -Np1 -i "$SOURCES/cyrus-sasl-2.1.28-gcc15_fixes-1.patch"
    autoreconf -fiv
    sed '/saslint/a #include <time.h>'       -i lib/saslutil.c
    sed '/plugin_common/a #include <time.h>' -i plugins/cram.c
}

build() {
    # The book's flags, with saslauthd's state in /run rather than
    # /var/run. Added from the optional dependencies that have recipes:
    # GSSAPI (MIT krb5) and PAM. Off: the SQL auxprop plugin (MariaDB and
    # PostgreSQL ship their servers in the same package as their client
    # libraries) and LDAP, both the ldapdb plugin and saslauthd's ldap
    # mechanism, because OpenLDAP is built against this library.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --enable-auth-sasldb \
        --with-dblib=lmdb \
        --with-dbpath=/var/lib/sasl/sasldb2 \
        --with-sphinx-build=no \
        --with-saslauthd=/run/saslauthd \
        --with-openssl=/usr \
        --enable-gssapi \
        --with-gss_impl=mit \
        --with-pam \
        --disable-sql \
        --disable-ldapdb \
        --without-ldap \
        --without-mysql \
        --without-pgsql \
        --without-sqlite \
        --without-sqlite3
    # The book builds serially.
    make -j1
}

package() {
    make -j1 DESTDIR="$DESTDIR" install

    # /var/lib/sasl holds the sasldb (book: install -dm700), and saslauthd
    # puts its socket in /run/saslauthd.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/cyrus-sasl.conf" << "EOT"
d /var/lib/sasl 0700 root root -
d /run/saslauthd 0755 root root -
EOT

    # "make install-saslauthd" from blfs-systemd-units: its defaults file
    # and unit. The unit is not enabled.
    install -d "$DESTDIR/etc/default" "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/etc/default/saslauthd" << "EOT"
# Begin /etc/default/saslauthd

# Which authentication mechanisms should saslauthd use? (default: shadow)
#
# Available options in this package:
# getpwent  -- use the getpwent() library function
# kerberos5 -- use Kerberos 5
# pam       -- use PAM
# rimap     -- use a remote IMAP server
# shadow    -- use the local shadow password file
# sasldb    -- use the local sasldb database file
#
# Only one option may be used at a time. See the saslauthd man page
# for more information.
#
# Example: MECHANISMS="shadow"
MECHANISMS="shadow"

# Additional options for this mechanism. (default: none)
# See the saslauthd man page for information about mech-specific options.
# Note: Specify "-O options" in the following variable or saslauthd will fail.
MECH_OPTIONS=""

# How many saslauthd processes should we run? (default: 5)
# A value of 0 will fork a new process for each connection.
THREADS=5

# Other options (default: -c -m /run/saslauthd)
# Note: You MUST specify the -m option or saslauthd won't run!
#
# See the saslauthd man page and the output of 'saslauthd -h' for general
# information about these options.
SASLAUTHD_OPTS="-c -m /run/saslauthd"

# End /etc/default/saslauthd
EOT
    cat > "$DESTDIR/usr/lib/systemd/system/saslauthd.service" << "EOT"
[Unit]
Description=Cyrus SASL authentication daemon

[Service]
Type=forking
EnvironmentFile=/etc/default/saslauthd
ExecStart=/usr/sbin/saslauthd -a $MECHANISMS -n $THREADS $MECH_OPTIONS $SASLAUTHD_OPTS
PIDFile=/run/saslauthd/saslauthd.pid

[Install]
WantedBy=multi-user.target
EOT
}
