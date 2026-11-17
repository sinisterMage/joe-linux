# Not in the book: the newest upstream release, built as its README says.
build() {
    # Without CFLAGS of its own configure adds -Werror to them, which turns
    # every new GCC warning into a failed build.
    export CFLAGS="${CFLAGS:--O2 -g}"
    # Sessions come from systemd-logind, not ConsoleKit. The systemd units
    # are installed, not the Red Hat init script.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-session-info=systemd \
        --with-init-script=systemd \
        --with-gtk=yes \
        --with-gtk4=no \
        --enable-pciaccess \
        --disable-static-uinput
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # Installed as upstream ships them and not enabled: the system daemon's
    # socket and service, the session agent's user unit, and the
    # tmpfiles.d entry for /run/spice-vdagentd. Upstream's udev rule starts
    # spice-vdagentd.socket when the SPICE agent channel
    # (/dev/virtio-ports/com.redhat.spice.0) appears, so the agent runs only
    # in SPICE guests; its XDG autostart entry starts the session agent,
    # which exits when the daemon is not running.
    #
    # The daemon reads extra arguments from Red Hat's /etc/sysconfig; the
    # file is optional (EnvironmentFile=-) and none is shipped.
}
