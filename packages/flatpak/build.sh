# Not in the book: the newest stable upstream release (1.18 series; odd
# minor versions are development releases), built with meson as its README
# says. No remotes are configured: Flathub or any other repository is added
# by the administrator (flatpak remote-add).
build() {
    mkdir build
    cd build
    # The bundled bubblewrap and xdg-dbus-proxy are replaced by the system's.
    # Members of wheel (joe's administrators) may install and remove
    # system-wide applications without a password, as upstream's polkit
    # rule intends. Off: parental controls (malcontent has no recipe),
    # SELinux, the API reference (gtk-doc) and the HTML manual (xmlto),
    # sideloading from USB drives.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D system_bubblewrap=/usr/bin/bwrap \
        -D system_dbus_proxy=/usr/bin/xdg-dbus-proxy \
        -D system_helper=enabled \
        -D privileged_group=wheel \
        -D dconf=enabled \
        -D libzstd=enabled \
        -D systemd=enabled \
        -D seccomp=enabled \
        -D xauth=enabled \
        -D wayland_security_context=enabled \
        -D gir=enabled \
        -D man=enabled \
        -D malcontent=disabled \
        -D selinux_module=disabled \
        -D gtkdoc=disabled \
        -D docbook_docs=disabled \
        -D auto_sideloading=false \
        -D gdm_env_file=false \
        -D tests=false \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # Upstream's sysusers file lets the system helper's account take any
    # id; /var is shared between deployments, so it gets a fixed one. The
    # system helper itself runs as root (D-Bus activated, unit not enabled).
    cat > "$DESTDIR/usr/lib/sysusers.d/flatpak.conf" << "EOT"
g flatpak 35
u flatpak 35:35 "Flatpak system helper" - /usr/bin/false
EOT
}
