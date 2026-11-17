# Following the book's OpenLDAP page, its server build.
prepare() {
    patch -Np1 -i "$SOURCES/openldap-2.7.2-consolidated-1.patch"
    autoconf
}

build() {
    # The book's server flags (Type=forking unit, so no systemd
    # notification). Not in the book, made explicit: no fetch(3) URL
    # support, no SLP and no TCP wrappers, which have no recipes.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libexecdir=/usr/lib \
        --disable-static \
        --disable-debug \
        --with-tls=openssl \
        --with-cyrus-sasl \
        --without-systemd \
        --without-fetch \
        --disable-slp \
        --disable-wrappers \
        --enable-dynamic \
        --enable-crypt \
        --enable-spasswd \
        --enable-slapd \
        --enable-modules \
        --enable-rlookups \
        --enable-backends=mod \
        --disable-sql \
        --disable-wt \
        --enable-overlays=mod
    make depend
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The slap* tools are links to slapd, made with $DESTDIR in their
    # targets; point them at slapd beside them.
    local link
    for link in "$DESTDIR"/usr/sbin/slap*; do
        if [[ -L $link ]]; then
            ln -sfn slapd "$link"
        fi
    done

    sed -e "s/\.la/.so/" -i "$DESTDIR"/etc/openldap/slapd.{conf,ldif}{,.default}

    # The account the book creates (groupadd -g 83, useradd -u 83).
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/openldap.conf" << "EOT"
g ldap 83
u ldap 83:83 "OpenLDAP Daemon Owner" /var/lib/openldap /usr/bin/false
EOT
    # The book's ownership and modes: the database directory and
    # slapd.d belong to ldap (700), slapd.conf and slapd.ldif are 640
    # root:ldap. /run/openldap is blfs-systemd-units' tmpfiles entry.
    chmod 640 "$DESTDIR"/etc/openldap/slapd.{conf,ldif}
    cat > "$DESTDIR/usr/lib/tmpfiles.d/openldap.conf" << "EOT"
d /var/lib/openldap 0700 ldap ldap -
d /run/openldap 0755 ldap ldap -
d /etc/openldap/slapd.d 0700 ldap ldap -
z /etc/openldap/slapd.conf 0640 root ldap -
z /etc/openldap/slapd.ldif 0640 root ldap -
EOT

    # "make install-slapd" from blfs-systemd-units. Not enabled.
    install -d "$DESTDIR/etc/default" "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/etc/default/slapd" << "EOT"
# Begin /etc/default/slapd

# Options to pass to slapd.
# See slapd(8) for more details.
SLAPD_OPTS=""

# slapd normally serves ldap only on all TCP-ports 389. slapd can also
# service requests on TCP-port 636 (ldaps) and requests via unix
# sockets.
#SLAPD_OPTS='-h "ldap://127.0.0.1:389/ ldaps:/// ldapi:///"'

# End /etc/default/slapd
EOT
    cat > "$DESTDIR/usr/lib/systemd/system/slapd.service" << "EOT"
[Unit]
Description=OpenLDAP server daemon
After=network.target
Documentation=man:slapd
Documentation=man:slapd-config
Documentation=man:slapd-mdb

[Service]
Type=forking
EnvironmentFile=/etc/default/slapd
ExecStart=/usr/sbin/slapd -u ldap -g ldap $SLAPD_OPTS

[Install]
WantedBy=multi-user.target
EOT
}
