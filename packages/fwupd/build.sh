# Not in the book: the newest upstream release, built with meson as its
# README.md says (and as distributions package it).
build() {
    mkdir build
    cd build
    # Every plugin that works through the kernel is built (NVMe, Thunderbolt
    # and USB4, Logitech, DFU, UEFI capsules, the host security checks...);
    # fwupd 2 has no per-plugin switches except the two below. The TPM
    # plugin, which reads the event log and PCRs for the host security
    # report, is built whenever pkg-config finds tpm2-tss. The capsule
    # splash images would be rendered at build time from every
    # translation, which needs fonts for every script in the build root;
    # without them the firmware shows its own progress. The UEFI program
    # comes from the fwupd-efi package (efi_binary would build it from a
    # subproject). Passim, which shares metadata with other machines on the
    # network, has no recipe. Only GnuTLS does the signature checking.
    # firmware-packager installs Python scripts for making firmware
    # archives. supported_build is what distributions set: it stops
    # fwupd.service aborting on the first GLib critical warning and the
    # tools warning that the build is unvalidated. The LVFS remotes are
    # installed and enabled; their metadata is downloaded at run time by
    # `fwupdmgr refresh`.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D build=all \
        -D docs=disabled \
        -D tests=false \
        -D umockdev_tests=disabled \
        -D valgrind=disabled \
        -D static_analysis=false \
        -D introspection=enabled \
        -D man=true \
        -D metainfo=true \
        -D bash_completion=true \
        -D fish_completion=true \
        -D systemd=enabled \
        -D logind=enabled \
        -D polkit=enabled \
        -D gnutls=enabled \
        -D openssl=disabled \
        -D blkid=enabled \
        -D libdrm=enabled \
        -D libmnl=enabled \
        -D readline=enabled \
        -D bluez=enabled \
        -D hsi=enabled \
        -D passim=disabled \
        -D plugin_modem_manager=enabled \
        -D plugin_uefi_capsule_splash=false \
        -D efi_binary=false \
        -D lvfs=true \
        -D vendor_metadata=false \
        -D firmware-packager=false \
        -D qubes=false \
        -D supported_build=enabled \
        -D vendor_ids_dir=/usr/share/hwdata \
        -D systemd_unit_user=fwupd-refresh
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # A GRUB script that adds a boot entry for fwupdx64.efi. joe boots with
    # systemd-boot and has no GRUB.
    rm "$DESTDIR/etc/grub.d/35_fwupd"
    rmdir "$DESTDIR/etc/grub.d"

    # fwupd-refresh.service runs `fwupdmgr refresh` as this account; the
    # daemon itself runs as root. Upstream lets systemd-sysusers pick the
    # id, but /var/cache/fwupdmgr outlives a deployment, so it is fixed.
    cat > "$DESTDIR/usr/lib/sysusers.d/fwupd.conf" << "EOF"
g fwupd-refresh 93
u fwupd-refresh 93:93 "Firmware update daemon" /var/lib/fwupd
EOF

    # fwupd.service is started over D-Bus when a client asks, and
    # fwupd-refresh.timer is shipped but not enabled.
}
