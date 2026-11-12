prepare() {
    # Groups joe does not define.
    sed -e 's/GROUP="render"/GROUP="video"/' \
        -e 's/GROUP="sgx", //' \
        -i rules.d/50-udev-default.rules.in
}

build() {
    mkdir -p build
    cd build
    # bootloader=enabled makes a missing dependency of systemd-boot an error
    # instead of silently building without it: joe cannot boot without it.
    # The distribution's Secure Boot revocation entry (sbat-distro) is left out
    # until joe signs its boot chain and has a project URL to put in it.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D mode=release \
        -D bootloader=enabled \
        -D efi=true \
        -D sbat-distro= \
        -D default-dnssec=no \
        -D firstboot=false \
        -D install-tests=false \
        -D ldconfig=false \
        -D sysusers=false \
        -D rpmmacrosdir=no \
        -D homed=disabled \
        -D man=disabled \
        -D pamconfdir=no \
        -D dev-kvm-mode=0660 \
        -D nobody-group=nogroup \
        -D sysupdate=disabled \
        -D ukify=disabled \
        -D vconsole=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
