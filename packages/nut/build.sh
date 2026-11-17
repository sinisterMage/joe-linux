# Not in the book: the newest upstream release, built as its INSTALL.nut.adoc
# and docs/configure.txt describe.
build() {
    # Paths: configuration in /etc/nut (upstream's default directory name;
    # given in full, since --sysconfdir alone would drop the "nut"), drivers
    # and nut-driver-enumerator.sh in /usr/lib/nut, driver sockets and
    # upssched state in /var/lib/nut, PID files of the unprivileged daemons
    # in /run/nut. upsd and the drivers drop root to the nut account.
    #
    # On: serial and USB (libusb-1.0) drivers, nut-upower (GLib/GIO),
    # OpenSSL, libsystemd, nut-scanner (libltdl; Avahi discovery opened at
    # run time), the PyNUT module, the development files (libupsclient and
    # libnutclient for other programs) and the manual pages shipped in the
    # tarball (asciidoc is not packaged).
    # Off because what they need has no recipe: SNMP drivers (net-snmp),
    # the XML/HTTP driver (neon), Powerman, Modbus (libmodbus), GPIO
    # (libgpiod), IPMI (FreeIPMI), I2C (i2c-tools), TCP wrappers, the CGI
    # programs (gd) and the NUT-Monitor GUI (PyQt). nutconf is
    # experimental. The systemd preset (which would enable the units) is
    # not installed.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --with-confdir=/etc/nut \
        --libexecdir=/usr/lib/nut \
        --with-drvpath=/usr/lib/nut \
        --with-statepath=/var/lib/nut \
        --with-altpidpath=/run/nut \
        --with-pidpath=/run \
        --with-user=nut \
        --with-group=nut \
        --disable-static \
        --with-serial \
        --with-usb=libusb-1.0 \
        --without-snmp \
        --without-neon \
        --without-powerman \
        --without-modbus \
        --without-gpio \
        --without-ipmi \
        --without-freeipmi \
        --without-linux_i2c \
        --without-macosx_ups \
        --with-upower \
        --with-avahi \
        --with-ssl \
        --with-openssl \
        --without-nss \
        --without-wrap \
        --with-libltdl \
        --with-nut-scanner \
        --without-cgi \
        --without-nut_monitor \
        --with-pynut=yes \
        --with-python=/usr/bin/python3 \
        --with-python3=/usr/bin/python3 \
        --without-python2 \
        --without-nutconf \
        --without-dev-libnutconf \
        --with-dev \
        --with-libsystemd \
        --with-docs=man=dist-auto \
        --enable-cppunit=no \
        --with-valgrind=no \
        --with-udev-dir=/usr/lib/udev \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-systemdshutdowndir=/usr/lib/systemd/system-shutdown \
        --with-systemdtmpfilesdir=/usr/lib/tmpfiles.d \
        --with-systemdsysusersdir=/usr/lib/sysusers.d \
        --with-systemdsystempresetdir=no \
        --with-augeas-lenses-dir=no \
        --with-hotplug-dir=no \
        --with-devd-dir=no \
        --with-freebsd-quirks-dir=no \
        --with-pkgconfig-dir=/usr/lib/pkgconfig
    make
}

package() {
    # Installs the drivers, upsd, upsmon and the clients, the *.sample
    # configuration files in /etc/nut (an administrator writes ups.conf,
    # upsd.conf, upsd.users and upsmon.conf from them), the udev rules
    # giving the nut group access to USB UPSes, upstream's tmpfiles.d file
    # (/var/lib/nut, /var/lib/nut/upssched and /run/nut, owned by nut) and
    # its units, none enabled: nut.target with nut-driver@.service (one per
    # UPS, made by nut-driver-enumerator), nut-server.service (upsd) and
    # nut-monitor.service (upsmon). nutshutdown, run by systemd at the very
    # end of shutdown, tells the UPS to cut power only when upsmon has
    # flagged a power failure.
    make DESTDIR="$DESTDIR" install

    # The account, with a fixed id in place of upstream's dynamic one.
    rm "$DESTDIR/usr/lib/sysusers.d/nut-common-sysusers.conf"
    cat > "$DESTDIR/usr/lib/sysusers.d/nut.conf" << "EOF"
g nut 95
u nut 95:95 "Network UPS Tools" /var/lib/nut /usr/bin/false
EOF
}
