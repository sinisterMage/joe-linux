# Not in the book. This is the newest release of the GNOME 51 series, built
# with upstream's meson options.
#
# How it comes to run (gdm 51, daemon/gdm-display.c and
# gdm-launch-environment.c): when accountsservice lists no ordinary user,
# /usr/share/gnome-session/sessions/gnome-initial-setup.session exists and
# daemon/InitialSetupEnable is not false (it defaults to true), gdm starts
# its own /usr/share/gdm/greeter/wayland-sessions/gnome-initial-setup.desktop
# ("gnome-session --session gnome-initial-setup") in place of the greeter.
# The session runs as a user named gnome-initial-setup that gdm allocates on
# the spot and announces through systemd's userdb, as it does for the
# greeter, with its home in /run/gdm/home. So there is no account and no
# directory to ship: the one thing gdm needs from the system is the *group*
# gnome-initial-setup, which it puts that user in and which the polkit rule
# installed here tests for.
build() {
    mkdir build
    cd build
    # - parental_controls needs malcontent, which has no recipe.
    # - webkitgtk only shows the distribution's privacy policy in a window.
    # - ibus: the keyboard page then offers input methods as well as layouts.
    # - gdm-rundir matches gdm's run-dir: gdm hands the setup user's home to
    #   the new user as /run/gdm/gnome-initial-setup, and the copy worker
    #   takes the settings chosen during setup from there at first login.
    # No vendor-conf-file: the search path stays
    # /etc/gnome-initial-setup/vendor.conf, then
    # /usr/share/gnome-initial-setup/vendor.conf. Neither is shipped; joe
    # has no installer that asks the same questions, so every page is shown.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D ibus=enabled \
        -D parental_controls=disabled \
        -D webkitgtk=disabled \
        -D gdm-rundir=/run/gdm
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # Upstream's sysusers.d file asks for a dynamic gid. Ids are fixed here;
    # 66 is not assigned by the book.
    cat > "$DESTDIR/usr/lib/sysusers.d/gnome-initial-setup.conf" <<'EOT'
g gnome-initial-setup 66
EOT
}
