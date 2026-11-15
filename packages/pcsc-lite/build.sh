# Not in the book: the newest upstream release, built with meson as
# README.md describes. KeePassXC links libpcsclite for hardware keys.
build() {
    mkdir build
    cd build
    # - systemdunit=system: pcscd.service and pcscd.socket are system units
    #   (the service runs as the pcscd user); they are not enabled.
    # - USB hot-plug through libudev, not libusb, as upstream prefers.
    # - No card reader drivers come with this package (CCID is separate);
    #   they go to /usr/lib/pcsc/drivers.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --sbindir=sbin \
        --buildtype=release \
        -D libsystemd=true \
        -D systemdunit=system \
        -D libudev=true \
        -D libusb=false \
        -D polkit=true \
        -D usb=true \
        -D serial=true \
        -D embedded=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # Upstream's sysusers.d file asks for a dynamic id; /var is shared
    # between deployments, so the pcscd user gets a fixed one, as every
    # system account does.
    rm "$DESTDIR/usr/lib/sysusers.d/pcscd-sysusers.conf"
    cat > "$DESTDIR/usr/lib/sysusers.d/pcscd.conf" <<'EOT'
g pcscd 54
u pcscd 54:54 "PC/SC smart card daemon" /run/pcscd /usr/bin/false
EOT
}
