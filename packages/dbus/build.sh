build() {
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
