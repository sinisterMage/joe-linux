build() {
    # Upstream's install script gives the launch helper to the messagebus
    # group and makes it set-uid whenever that user exists, as it does in the
    # build root, where the chown fails. Files are root's (packages/README.md),
    # so the helper stays as the script leaves it when the user does not
    # exist: not set-uid.
    sed -i 's/^        if os.getuid() == 0:$/        if False:/' meson_post_install.py
    mkdir build
    cd build
    meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # /var/lib/dbus/machine-id must mirror /etc/machine-id; /var is not packaged.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/joe-dbus.conf" <<'EOT'
d /var/lib/dbus 0755 root root -
L /var/lib/dbus/machine-id - - - - /etc/machine-id
EOT
}
