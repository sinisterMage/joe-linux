build() {
    # Plugins built: btrfs, crypto, fs, loop, mdraid, nvme, part, smart
    # (libatasmart) and swap. UDisks will not configure without crypto, fs,
    # loop, mdraid, nvme, part and swap. Left out: lvm, lvm_dbus, dm and
    # mpath (device-mapper clients), nvdimm (ndctl), escrow (volume_key),
    # smartmontools, the command line tools (parted) and the Python
    # overrides.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --enable-introspection=yes \
        --without-python3 \
        --without-gtk-doc \
        --without-escrow \
        --without-tools \
        --without-lvm \
        --without-lvm_dbus \
        --without-dm \
        --without-mpath \
        --without-nvdimm \
        --without-smartmontools \
        --with-btrfs \
        --with-crypto \
        --with-fs \
        --with-loop \
        --with-mdraid \
        --with-nvme \
        --with-part \
        --with-smart \
        --with-swap
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
