prepare() {
    patch -Np1 -i "$SOURCES/avahi-0.9-rc5-ipv6_race_condition_fix-1.patch"
}

build() {
    autoreconf -fiv
    # The book's switches, with these differences:
    # - Python D-Bus tools and bindings are available; the GTK and Python
    #   GObject user interfaces stay off.
    # - the libevent binding is built;
    # - the manual pages need xmltoman, which is not packaged, and the
    #   avahi-core API documentation needs Doxygen.
    # Stated besides: libsystemd (socket activation, notification),
    # introspection data for the GObject binding, GDBM for the service type
    # database, the unit and D-Bus policy directories, and the accounts
    # below.
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --enable-glib \
        --enable-gobject \
        --enable-introspection \
        --enable-libevent \
        --enable-libdaemon \
        --enable-libsystemd \
        --enable-gdbm \
        --enable-autoipd \
        --disable-gtk \
        --disable-gtk3 \
        --disable-mono \
        --disable-monodoc \
        --disable-manpages \
        --enable-python \
        --disable-pygobject \
        --enable-python-dbus \
        --disable-qt3 \
        --disable-qt4 \
        --disable-qt5 \
        --disable-core-docs \
        --disable-compat-libdns_sd \
        --disable-compat-howl \
        --with-distro=none \
        --with-xml=expat \
        --with-avahi-user=avahi \
        --with-avahi-group=avahi \
        --with-avahi-priv-access-group=netdev \
        --with-autoipd-user=avahi-autoipd \
        --with-autoipd-group=avahi-autoipd \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-dbus-sys=/usr/share/dbus-1/system.d \
        --with-dbus-system-address='unix:path=/run/dbus/system_bus_socket'
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The accounts the book creates: avahi (84), and avahi-autoipd, which
    # the book leaves to configure's defaults, with id 85. netdev (86),
    # whose members may use Avahi's privileged D-Bus calls, is also
    # declared by networkmanager; the two lines agree. avahi-daemon and
    # avahi-autoipd create their own directories under /run and /var/lib.
    install -d "$DESTDIR/usr/lib/sysusers.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/avahi.conf" << "EOF"
g avahi 84
u avahi 84:84 "Avahi Daemon Owner" /run/avahi-daemon /usr/bin/false
g avahi-autoipd 85
u avahi-autoipd 85:85 "Avahi IPv4LL Daemon" /var/lib/avahi-autoipd /usr/bin/false
g netdev 86
EOF

    # The book turns off systemd-resolved's own mDNS responder, which would
    # compete with avahi-daemon for port 5353. Neither avahi-daemon nor
    # avahi-dnsconfd is enabled.
    install -d "$DESTDIR/etc/systemd/resolved.conf.d"
    cat > "$DESTDIR/etc/systemd/resolved.conf.d/no-mdns.conf" << "EOF"
[Resolve]
MulticastDNS=no
EOF
}
