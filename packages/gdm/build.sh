build() {
    mkdir build
    cd build
    # The book passes gdm-xsession=true and run-dir; here:
    # - x11-support and gdm-xsession are off: they start an Xorg server for
    #   X11 sessions and there is none. Sessions and the greeter are Wayland;
    #   X applications run through Xwayland, which is mutter's business.
    # - default-pam-config=lfs installs the book's PAM files; distro=none
    #   stops meson from guessing a distribution from /etc/*-release.
    # - plymouth, SELinux and libaudit do not exist here.
    # This version has no user, xdmcp, wayland-support or udev-dir options
    # any more: the greeter runs as a user that gdm allocates dynamically
    # (through systemd's userdb) and adds to the gdm group.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D default-pam-config=lfs \
        -D distro=none \
        -D gdm-xsession=false \
        -D x11-support=false \
        -D run-dir=/run/gdm \
        -D group=gdm \
        -D logind-provider=systemd \
        -D systemd-journal=true \
        -D plymouth=disabled \
        -D selinux=disabled \
        -D libaudit=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # The book's PAM file for the sessions gdm starts itself admits members
    # of the gdm group only, because the book has no first-run setup. That
    # session runs as a user whose group is gnome-initial-setup (see the
    # gnome-initial-setup recipe); upstream's own files name both groups.
    sed -i 's/user ingroup gdm$/user ingroup gdm:gnome-initial-setup/' \
        "$DESTDIR/usr/lib/pam.d/gdm-launch-environment"
    [[ $(grep -c 'ingroup gdm:gnome-initial-setup$' "$DESTDIR/usr/lib/pam.d/gdm-launch-environment") -eq 3 ]]

    # The book's "groupadd -g 21 gdm". There is no gdm user any more: the
    # greeter's users are dynamic and only need this group to exist.
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/gdm.conf" <<'EOT'
g gdm 21
EOT

    # The directories the daemon expects, with the owners and modes it would
    # give them itself (gdm_daemon_ensure_dirs and the working directory
    # check in gdm-launch-environment.c).
    cat > "$DESTDIR/usr/lib/tmpfiles.d/gdm.conf" <<'EOT'
d /run/gdm 0755 root root -
d /var/lib/gdm 0755 root root -
d /var/log/gdm 0711 root gdm -
EOT
}
