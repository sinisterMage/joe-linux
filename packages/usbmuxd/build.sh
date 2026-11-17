# Not in the book: upstream's newest release, built as its README says.
# 1.1.1 (2020) is still the newest; upstream's development branch has
# unreleased fixes since, which distributions take as git snapshots.

prepare() {
    # libplist 2.3 and later define enum plist_format_t themselves (Arch
    # Linux's patch for the same).
    patch -Np1 -i /recipe/libplist-2.3.patch
}

build() {
    # Started by systemd: upstream's udev rule asks for usbmuxd.service
    # (SYSTEMD_WANTS) when an Apple device is plugged in, and usbmuxd exits
    # when the last one is removed. That is how upstream installs it, and
    # the service is not otherwise enabled. The preflight worker is built
    # by default, and configure stops if libimobiledevice is missing
    # (--with-preflight would actually turn it off).
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-systemd \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-udevrulesdir=/usr/lib/udev/rules.d
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The account usbmuxd drops to. It makes /var/lib/lockdown, where pair
    # records are kept, itself, and gives it to this account.
    install -d "$DESTDIR/usr/lib/sysusers.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/usbmuxd.conf" << "EOT"
g usbmux 36
u usbmux 36:36 "usbmux daemon" /var/lib/lockdown /usr/bin/false
EOT
}
