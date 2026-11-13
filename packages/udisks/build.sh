build() {
    # The book's --enable-available-modules builds whatever it finds. Named
    # here instead: the btrfs module (libblockdev's btrfs plugin) is built;
    # LVM2, iSCSI (libiscsi) and LibStorageMgmt are not. The manual pages
    # would need the DocBook stylesheets at build time.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --disable-gtk-doc \
        --disable-man \
        --enable-introspection=yes \
        --enable-daemon \
        --enable-acl \
        --enable-smart \
        --enable-btrfs \
        --disable-lvm2 \
        --disable-iscsi \
        --disable-lsm \
        --with-udevdir=/usr/lib/udev \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-tmpfilesdir=/usr/lib/tmpfiles.d
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # make install creates /var/lib/udisks2 (mode 0700), which is not
    # packaged. Upstream's own tmpfiles.d/udisks2.conf covers /run/media.
    cat > "$DESTDIR/usr/lib/tmpfiles.d/udisks.conf" <<'EOT'
d /var/lib/udisks2 0700 root root -
EOT
}
