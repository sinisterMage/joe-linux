# The part of upstream's firmware that packages/linux-firmware leaves out, as
# Arch splits it into linux-firmware-qcom, -mellanox, -nfp, -qlogic and
# -liquidio: Qualcomm's Arm systems on chips (whose cellular modems, which
# PCs carry, stay in linux-firmware), and the network and switch chips of
# servers. Installed as linux-firmware installs, compressed with zstd. The
# list is the same as in linux-firmware's build.sh; change both together.
#
# Some firmware files are ELF executables for a device's own processor;
# stripping them would break them.
NOSTRIP=1

extra_firmware=(qcom 'a300_*.fw.zst' mellanox mrvl/prestera netronome qed qlogic liquidio dpaa2 'ql2[0-9]*_fw.bin.zst')

package() {
    local all=$PWD/joe-all path
    make DESTDIR="$all" FIRMWAREDIR=/usr/lib/firmware install-zst
    rm -rf "$all"/usr/lib/firmware/qcom/sdx*
    install -d "$DESTDIR/usr/lib/firmware"
    # Unquoted, so that the patterns expand in the firmware directory.
    for path in "${extra_firmware[@]}"; do
        (cd "$all/usr/lib/firmware" && cp -a --parents $path "$DESTDIR/usr/lib/firmware/")
    done
}
