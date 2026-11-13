prepare() {
    patch -Np1 -i "$SOURCES/mitkrb-1.22.2-upstream_fix-1.patch"
    patch -Np1 -i "$SOURCES/mitkrb-1.22.2-security_fix-1.patch"
    patch -Np1 -i "$SOURCES/mitkrb-1.22.2-openssl_4_fixes-1.patch"
}

build() {
    cd src
    # com_err and ss come from e2fsprogs. No OpenLDAP and no LMDB back ends
    # for the KDC database, no libedit; keyutils gives the KEYRING
    # credential cache.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var/lib \
        --runstatedir=/run \
        --with-system-et \
        --with-system-ss \
        --with-system-verto=no \
        --enable-dns-for-realm \
        --disable-rpath \
        --with-keyutils \
        --without-ldap \
        --without-lmdb \
        --without-libedit
    make
}

package() {
    cd src
    make DESTDIR="$DESTDIR" install

    # The book's krb5.conf is a form to be filled in with the site's realm
    # and KDC. The libraries work without the file (empty profile, realm
    # and KDC found through DNS), so it is shipped as a commented template.
    install -d "$DESTDIR/etc"
    cat > "$DESTDIR/etc/krb5.conf" << "EOF"
# Begin /etc/krb5.conf
#
# Without settings here the realm and its KDCs are looked up in DNS.
# To name them, remove the comment signs and replace the upper- and
# lower-case EXAMPLE.ORG and the host name.
#
#[libdefaults]
#    default_realm = EXAMPLE.ORG
#    encrypt = true
#
#[realms]
#    EXAMPLE.ORG = {
#        kdc = belgarath.example.org
#        admin_server = belgarath.example.org
#        dict_file = /usr/share/dict/words
#    }
#
#[domain_realm]
#    .example.org = EXAMPLE.ORG
#
#[logging]
#    kdc = SYSLOG:INFO:AUTH
#    admin_server = SYSLOG:INFO:AUTH
#    default = SYSLOG:DEBUG:DAEMON

# End /etc/krb5.conf
EOF

    # No KDC is set up or enabled (the book's units are not installed); the
    # database directory exists for whoever runs kdb5_util.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/krb5.conf" <<'EOT'
d /var/lib/krb5kdc 0700 root root -
EOT
}
