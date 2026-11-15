# Not in the book: the newest upstream release, built as its README says.
build() {
    # The daemon, iwctl (readline; libedit is not packaged) and iwmon, with
    # the embedded Linux library built in from the tarball. The manual
    # pages ship ready-made. Not built: ead (802.1X on wired ports), the
    # hwsim and test tools, oFono SIM authentication.
    #
    # Installed with it, as upstream intends: iwd.service and the D-Bus
    # activation file (nothing is enabled; NetworkManager in joe uses
    # wpa_supplicant), a .link file that keeps the kernel's names for Wi-Fi
    # interfaces, and a modules-load.d file for the PKCS#8 key parser.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libexecdir=/usr/lib/iwd \
        --enable-daemon \
        --enable-client \
        --enable-monitor \
        --enable-dbus-policy \
        --enable-systemd-service \
        --enable-manual-pages \
        --with-dbus-datadir=/usr/share \
        --with-dbus-busdir=/usr/share/dbus-1/system-services \
        --with-systemd-unitdir=/usr/lib/systemd/system \
        --with-systemd-networkdir=/usr/lib/systemd/network \
        --with-systemd-modloaddir=/usr/lib/modules-load.d \
        --disable-external-ell \
        --disable-libedit \
        --disable-wired \
        --disable-hwsim \
        --disable-tools \
        --disable-ofono
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
