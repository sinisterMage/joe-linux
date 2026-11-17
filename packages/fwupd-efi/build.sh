# Not in the book: the newest upstream release, built with meson as its
# README.md says.
build() {
    mkdir build
    cd build
    # gnu-efi installs its libraries, start-up object and linker scripts
    # straight into /usr/lib. Python pefile sets NX compatibility on the PE
    # output, so the alternative genpeimg tool is unnecessary. The SBAT entry
    # names the distribution for shim under Secure Boot.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D efi-libdir=/usr/lib \
        -D efi-ldsdir=/usr/lib \
        -D efi-includedir=/usr/include/efi \
        -D genpeimg=disabled \
        -D efi_sbat_distro_id=joe \
        -D efi_sbat_distro_summary="joe Linux" \
        -D efi_sbat_distro_pkgname=fwupd-efi \
        -D efi_sbat_distro_version="$PKG_RELEASE" \
        -D efi_sbat_distro_url=https://github.com/sinisterMage/joe-linux
    ninja
}

package() {
    # /usr/libexec/fwupd/efi/fwupdx64.efi, where fwupd looks for it, and
    # fwupd-efi.pc. fwupd copies the program to the ESP when it schedules
    # an update.
    cd build
    DESTDIR="$DESTDIR" ninja install
}
