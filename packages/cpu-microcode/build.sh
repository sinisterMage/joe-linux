# The book's firmware page (postlfs/firmware) describes this: the kernel
# applies microcode early from an uncompressed cpio passed to it as an
# initrd, holding kernel/x86/microcode/GenuineIntel.bin and AuthenticAMD.bin.
# joe systems boot without an initramfs, so this archive is all their initrd
# holds, and the kernel goes on to mount the root itself. dave copies
# /usr/lib/joe/microcode.img to the EFI system partition and names it in the
# boot entry of every deployment.
#
# Intel's files are in this source; AMD's come from linux-firmware.
build() {
    mkdir -p early/kernel/x86/microcode
    cat intel-ucode/* > early/kernel/x86/microcode/GenuineIntel.bin
    local f
    for f in /usr/lib/firmware/amd-ucode/microcode_amd*.bin*; do
        case $f in
            *.zst) zstd -qdc "$f" ;;
            *) cat "$f" ;;
        esac
    done > early/kernel/x86/microcode/AuthenticAMD.bin
    [[ -s early/kernel/x86/microcode/GenuineIntel.bin && -s early/kernel/x86/microcode/AuthenticAMD.bin ]]
    (cd early && find . -mindepth 1 | LC_ALL=C sort | cpio --quiet -o -H newc -R 0:0 --reproducible) > microcode.img
}

package() {
    install -Dm644 microcode.img "$DESTDIR/usr/lib/joe/microcode.img"
    install -Dm644 license "$DESTDIR/usr/share/licenses/cpu-microcode/intel-license" 2>/dev/null || true
}
