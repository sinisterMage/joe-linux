# Kernel modules and the kernel image must not be passed through strip.
NOSTRIP=1

prepare() {
    make mrproper
    # The joe security module lives in this recipe, not in a kernel fork.
    /recipe/joe-lsm/install.sh /recipe/joe-lsm
    make x86_64_defconfig
    scripts/kconfig/merge_config.sh -m .config /recipe/joe.config
    make olddefconfig
    # Fail now, not at boot, if an option the boot path depends on was
    # dropped, or one whose absence shows only as a silent or flat desktop.
    local opt
    for opt in EFI_STUB BTRFS_FS VIRTIO_BLK BLK_DEV_NVME SATA_AHCI VFAT_FS EFIVAR_FS DEVTMPFS_MOUNT AUTOFS_FS \
        SECURITY_JOE FS_VERITY CRYPTO_ECDSA \
        DRM_VIRTIO_GPU SND_HDA_INTEL SND_HDA_GENERIC SND_VIRTIO VIRTIO_FS \
        BLK_DEV_INITRD RD_ZSTD ISO9660_FS BLK_DEV_LOOP BLK_DEV_SR EROFS_FS EROFS_FS_ZIP_LZMA OVERLAY_FS \
        USB_STORAGE USB_UAS VMD MMC_BLOCK MMC_SDHCI_PCI FW_LOADER_COMPRESS_ZSTD SND_HDA_CODEC_REALTEK \
        SND_HDA_CODEC_HDMI WIRELESS CFG80211_USE_KERNEL_REGDB_KEYS; do
        grep -q "^CONFIG_$opt=y" .config || { echo "CONFIG_$opt is not built in" >&2; return 1; }
    done
    # Drivers that need firmware from the root: modules, or they could never
    # load it.
    for opt in DRM_I915 DRM_XE DRM_AMDGPU DRM_NOUVEAU CFG80211 MAC80211 IWLWIFI ATH11K_PCI RTW89_8852CE MT7921E \
        SND_SOC_SOF_PCI MAC80211_HWSIM; do
        grep -q "^CONFIG_$opt=m" .config || { echo "CONFIG_$opt is not a module" >&2; return 1; }
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
