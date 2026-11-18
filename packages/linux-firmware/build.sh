# Not a book package: the book's firmware page (postlfs/firmware) picks the
# files one machine needs. A distribution installs all of them, as upstream's
# install-zst does: each file zstd-compressed (the kernel decompresses it,
# FW_LOADER_COMPRESS_ZSTD), and the duplicates upstream lists in WHENCE as
# links. The licence of each file is in WHENCE and the LICENCE.* files, which
# are installed with it.
#
# Some firmware files are ELF executables for a device's own processor;
# stripping them would break them.
NOSTRIP=1

# Firmware for what PCs do not have is in linux-firmware-extra instead, as
# Arch's linux-firmware leaves out its -qcom, -mellanox, -nfp, -qlogic and
# -liquidio parts: Qualcomm's Arm systems on chips (but not the cellular
# modems PCs carry, qcom/sdx*), and the network and switch chips of servers.
# That is half of the whole. linux-firmware-extra's build.sh has the same
# list; change both together.
extra_firmware=(qcom 'a300_*.fw.zst' mellanox mrvl/prestera netronome qed qlogic liquidio dpaa2 'ql2[0-9]*_fw.bin.zst')

package() {
    make DESTDIR="$DESTDIR" FIRMWAREDIR=/usr/lib/firmware install-zst
    local fw=$DESTDIR/usr/lib/firmware modems=$PWD/joe-modems path
    mkdir -p "$modems"
    mv "$fw"/qcom/sdx* "$modems/"
    # Unquoted, so that the patterns expand in the firmware directory.
    for path in "${extra_firmware[@]}"; do
        (cd "$fw" && rm -r $path)
    done
    mkdir -p "$fw/qcom"
    mv "$modems"/* "$fw/qcom/"
    install -d "$DESTDIR/usr/share/licenses/linux-firmware"
    cp WHENCE LICENCE.* LICENSE.* "$DESTDIR/usr/share/licenses/linux-firmware/" 2>/dev/null || true
}
