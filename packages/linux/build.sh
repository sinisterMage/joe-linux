# Kernel modules and the kernel image must not be passed through strip.
NOSTRIP=1

prepare() {
    make mrproper
    make x86_64_defconfig
    scripts/kconfig/merge_config.sh -m .config /recipe/joe.config
    make olddefconfig
    # Fail now, not at boot, if an option the boot path depends on was dropped.
    local opt
    for opt in EFI_STUB BTRFS_FS VIRTIO_BLK BLK_DEV_NVME SATA_AHCI VFAT_FS EFIVAR_FS DEVTMPFS_MOUNT AUTOFS_FS; do
        grep -q "^CONFIG_$opt=y" .config || { echo "CONFIG_$opt is not built in" >&2; return 1; }
    done
}

build() {
    make
}

package() {
    local release
    release=$(make -s kernelrelease)
    make INSTALL_MOD_PATH="$DESTDIR/usr" INSTALL_MOD_STRIP=1 DEPMOD=/usr/sbin/depmod modules_install
    # dave looks for the kernel image here and copies it to the EFI system
    # partition when it creates a deployment.
    install -Dm644 arch/x86/boot/bzImage "$DESTDIR/usr/lib/modules/$release/vmlinuz"
    install -Dm644 .config "$DESTDIR/usr/lib/modules/$release/config"
    rm -f "$DESTDIR/usr/lib/modules/$release"/{build,source}

    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/20-depmod.zon" <<EOT
.{
    .name = "kernel module dependencies",
    .paths = .{"usr/lib/modules/$release/"},
    .exec = .{ "/usr/sbin/depmod", "$release" },
}
EOT
}
