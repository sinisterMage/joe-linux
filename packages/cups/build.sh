prepare() {
    # The book names firefox as the program that opens the web interface
    # from the menu entry; xdg-open opens whatever browser the user chose.
    sed -i 's#@CUPS_HTMLVIEW@#xdg-open#' desktop/cups.desktop.in

    # "make install" gives the configuration and spool directories to the
    # lp user and group (install -o/-g). Packaged files belong to root and
    # the build has no lp user, so the ownership is dropped here and set at
    # boot by usr/lib/tmpfiles.d/cups.conf instead.
    sed -i -e 's/ -o $(CUPS_USER)//' \
        -e 's/ -g $(CUPS_GROUP)//' \
        -e 's/ -g $(CUPS_PRIMARY_SYSTEM_GROUP)//' \
        conf/Makefile scheduler/Makefile notifier/Makefile
    if grep -n -e '-[og] $(CUPS_' conf/Makefile scheduler/Makefile notifier/Makefile; then
        return 1
    fi
}

build() {
    # The book's options, plus:
    # - the print user and group: configure would take them from the build
    #   root's /etc/passwd, which has no lp user;
    # - everything optional stated: DNS-SD through Avahi (which is why the
    #   book's patch for building without Avahi is not needed), D-Bus with
    #   its policy in /usr/share/dbus-1, libusb, PAM, POSIX ACLs and systemd
    #   socket activation are on; libpaper has no recipe; GSSAPI is
    #   deprecated upstream and off by default;
    # - no SysV init scripts or xinetd file.
    ./configure --libdir=/usr/lib \
        --with-rundir=/run/cups \
        --with-system-groups=lpadmin \
        --with-docdir=/usr/share/cups/doc-2.4.20 \
        --with-cups-user=lp \
        --with-cups-group=lp \
        --with-tls=gnutls \
        --with-dnssd=avahi \
        --enable-dbus \
        --with-dbusdir=/usr/share/dbus-1 \
        --enable-libusb \
        --enable-pam \
        --enable-acl \
        --disable-libpaper \
        --disable-gssapi \
        --with-ondemand=systemd \
        --with-systemd=/usr/lib/systemd/system \
        --with-rcdir=no \
        --with-xinetd=no
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    echo "ServerName /run/cups/cups.sock" > "$DESTDIR/etc/cups/client.conf"

    install -d "$DESTDIR/etc/pam.d"
    cat > "$DESTDIR/etc/pam.d/cups" << "EOF2"
# Begin /etc/pam.d/cups

auth    include system-auth
account include system-account
session include system-session

# End /etc/pam.d/cups
EOF2

    # The book's "useradd -u 9 lp" (its group lp, 9, comes with
    # joe-filesystem) and "groupadd -g 19 lpadmin".
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/cups.conf" << "EOF2"
u lp 9:9 "Print Service User" /var/spool/cups /usr/bin/false
g lpadmin 19
EOF2

    # The directories "make install" would create under /run and /var, and
    # the group it gives to the configuration, with the same modes.
    cat > "$DESTDIR/usr/lib/tmpfiles.d/cups.conf" << "EOF2"
d /run/cups 0755 root root -
d /run/cups/certs 0511 lp lpadmin -
d /var/spool/cups 0710 root lp -
d /var/spool/cups/tmp 1770 root lp -
d /var/cache/cups 0770 root lp -
d /var/cache/cups/rss 0775 root lp -
d /var/log/cups 0755 root root -
z /etc/cups 0755 root lp -
z /etc/cups/ppd 0755 root lp -
z /etc/cups/ssl 0700 root lp -
z /etc/cups/cupsd.conf 0640 root lp -
z /etc/cups/cupsd.conf.default 0640 root lp -
z /etc/cups/cups-files.conf 0640 root lp -
z /etc/cups/cups-files.conf.default 0640 root lp -
z /etc/cups/snmp.conf 0640 root lp -
z /etc/cups/snmp.conf.default 0640 root lp -
EOF2
}
