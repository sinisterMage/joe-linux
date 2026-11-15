prepare() {
    # configure finds out how Samba can switch user ids by running a test
    # program. As root it actually switches to uid 1 and back, which fails
    # in the build's user namespace, where uid 0 is the only one there is;
    # run as anyone else, it only checks that the calls exist. Take the
    # second path, as an unprivileged build of Samba does.
    sed -i '/^int main(void)$/,/^}$/s/if (getuid() != 0) {/if (1) {/' source3/lib/util_sec.c
    grep -q 'if (1) {' source3/lib/util_sec.c
}

build() {
    # The book's switches, less the self tests (and the Python modules it
    # installs into a virtual environment for them, which only the tests
    # and the AD DC need). There is no OpenLDAP, so there is no Active
    # Directory at all: no domain controller (as in the book), and no domain
    # membership (ADS) or LDAP either. Winbind still serves NT4-style
    # domains and local mapping.
    #
    # Libraries: talloc and popt come from the system; tevent, tdb and ldb
    # are Samba's own copies, installed as its private libraries.
    #
    # Optional parts on: CUPS printing (smbspool, the spoolss server and the
    # CUPS smb backend), Avahi announcement, PAM (pam_winbind), quotas,
    # JSON audit logging (jansson), LMDB as an ldb back end, smbclient's tar
    # mode (libarchive), the registry editor (ncurses), and the manual
    # pages, made with xsltproc and the DocBook stylesheets. Off, for want
    # of their dependencies: GPGME, libunwind, LTTng, FAM, DMAPI,
    # GlusterFS, Ceph, Spotlight (Tracker), clustering (CTDB), winexe
    # (mingw), the systemd user database (libvarlink).
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-piddir=/run/samba \
        --with-pammodulesdir=/usr/lib/security \
        --enable-fhs \
        --without-ad-dc \
        --without-ads \
        --without-ldap \
        --with-system-mitkrb5 \
        --with-systemd \
        --disable-rpath-install \
        --systemd-install-services \
        --bundled-libraries='!talloc,!popt,tevent,tdb' \
        --with-winbind \
        --with-pam \
        --with-quotas \
        --with-acl-support \
        --with-json \
        --with-libarchive \
        --with-regedit \
        --enable-cups \
        --enable-iprint \
        --enable-avahi \
        --without-gpgme \
        --without-libunwind \
        --without-lttng \
        --without-fam \
        --without-dmapi \
        --without-winexe \
        --without-cluster-support \
        --without-systemd-userdb \
        --disable-glusterfs \
        --disable-cephfs \
        --disable-cephrgw \
        --disable-spotlight
    make
}

package() {
    # The book's fix of the interpreter line of the installed scripts.
    sed '1s@^.*$@#!/usr/bin/python3@' \
        -i ./bin/default/source4/scripting/bin/*.inst
    make DESTDIR="$DESTDIR" install

    # samba.service starts the AD DC, which is not built.
    rm "$DESTDIR/usr/lib/systemd/system/samba.service"

    # The book's example configuration. No smb.conf is installed: writing
    # one (from this example, see the book) is what setting up a server is.
    install -v -dm755 "$DESTDIR/etc/samba"
    install -v -m644 examples/smb.conf.default "$DESTDIR/etc/samba"
    sed -e "s;log file =.*;log file = /var/log/samba/%m.log;" \
        -e "s;path = /usr/spool/samba;path = /var/spool/samba;" \
        -i "$DESTDIR/etc/samba/smb.conf.default"

    # Printing to Windows printers through CUPS (the book's link).
    install -dvm 755 "$DESTDIR/usr/lib/cups/backend"
    ln -v -sf /usr/bin/smbspool "$DESTDIR/usr/lib/cups/backend/smb"

    # The directories make install creates under /var and /run, which are
    # not packaged. The private directory holds the password database.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/samba.conf" << "EOF"
d /run/samba 0755 root root -
d /run/lock/samba 0755 root root -
d /var/lib/samba 0755 root root -
d /var/lib/samba/private 0700 root root -
d /var/cache/samba 0755 root root -
d /var/log/samba 0755 root root -
EOF
}
