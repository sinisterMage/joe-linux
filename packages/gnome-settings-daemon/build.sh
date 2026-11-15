build() {
    mkdir build
    cd build
    # The book builds with the defaults; here every plugin is stated:
    # - cups (printer notifications) and wwan (ModemManager) are on.
    # - smartcard: nothing can log in with a smart card here (no pam_pkcs11),
    #   so the service would only idle.
    # - usb-protection has no build dependency; it does nothing unless
    #   USBGuard is running.
    # The Wacom plugin no longer exists (mutter configures tablets).
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D systemd=true \
        -D systemd-units=true \
        -D elogind=false \
        -D alsa=true \
        -D gudev=true \
        -D network_manager=true \
        -D rfkill=true \
        -D colord=true \
        -D xwayland=true \
        -D usb-protection=true \
        -D smartcard=false \
        -D gcr3=false \
        -D cups=true \
        -D wwan=true \
        -D udev_dir=/usr/lib/udev
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
