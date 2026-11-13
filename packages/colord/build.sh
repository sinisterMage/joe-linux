prepare() {
    # The install script hands /var/lib/colord to the daemon user. /var is
    # not packaged and that user does not exist in the build root; the
    # tmpfiles.d file that the package installs does it at boot.
    sed -i '/chown/d' meson_post_install.sh
}

build() {
    mkdir build
    cd build
    # No ArgyllCMS (sensor driver, print profiles), no SANE, no
    # bash-completion; the manual pages need the DocBook 5 stylesheets. The
    # session example needs gnome-desktop and colord-gtk.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D daemon=true \
        -D daemon_user=colord \
        -D systemd=true \
        -D udev_rules=true \
        -D pnp_ids=/usr/share/hwdata/pnp.ids \
        -D introspection=true \
        -D vapi=true \
        -D libcolordcompat=true \
        -D argyllcms_sensor=false \
        -D print_profiles=false \
        -D sane=false \
        -D session_example=false \
        -D bash_completion=false \
        -D docs=false \
        -D man=false \
        -D tests=false \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # Upstream's sysusers.d file asks for a dynamic id. Replaced by the
    # account as the book creates it (groupadd -g 71, useradd -u 71).
    # /var/lib/colord and its ownership come from upstream's
    # usr/lib/tmpfiles.d/colord.conf.
    rm "$DESTDIR/usr/lib/sysusers.d/colord-sysusers.conf"
    cat > "$DESTDIR/usr/lib/sysusers.d/colord.conf" <<'EOT'
g colord 71
u colord 71:71 "Color Daemon Owner" /var/lib/colord /usr/bin/false
EOT
}
