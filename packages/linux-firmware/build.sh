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

package() {
    make DESTDIR="$DESTDIR" FIRMWAREDIR=/usr/lib/firmware install-zst
    install -d "$DESTDIR/usr/share/licenses/linux-firmware"
    cp WHENCE LICENCE.* LICENSE.* "$DESTDIR/usr/share/licenses/linux-firmware/" 2>/dev/null || true
}
