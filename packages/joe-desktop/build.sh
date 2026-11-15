# What makes the installed components a desktop: which services start, and
# who manages the network. Services are enabled by shipping the links
# `systemctl enable` would create, because packages have no install scripts.
package() {
    local system="$DESTDIR/usr/lib/systemd/system" user="$DESTDIR/usr/lib/systemd/user"

    # graphical.target, systemd's default, starts whatever is the display manager.
    install -d "$system/multi-user.target.wants"
    ln -s gdm.service "$system/display-manager.service"
    local unit
    for unit in NetworkManager accounts-daemon upower udisks2 ModemManager; do
        ln -s "../$unit.service" "$system/multi-user.target.wants/$unit.service"
    done

    # Daemons that are also started over D-Bus: the alias `systemctl enable`
    # makes from the unit's Alias= line is the name D-Bus activates.
    ln -s ModemManager.service "$system/dbus-org.freedesktop.ModemManager1.service"
    install -d "$system/bluetooth.target.wants"
    ln -s ../bluetooth.service "$system/bluetooth.target.wants/bluetooth.service"
    ln -s bluetooth.service "$system/dbus-org.bluez.service"
    install -d "$system/sockets.target.wants"
    ln -s ../avahi-daemon.service "$system/multi-user.target.wants/avahi-daemon.service"
    ln -s ../avahi-daemon.socket "$system/sockets.target.wants/avahi-daemon.socket"
    ln -s avahi-daemon.service "$system/dbus-org.freedesktop.Avahi.service"

    # CUPS starts when something prints or a queue has work: the socket and
    # the spool watcher, as `systemctl enable cups` sets them up (Also=).
    ln -s ../cups.socket "$system/sockets.target.wants/cups.socket"
    ln -s ../cups.path "$system/multi-user.target.wants/cups.path"

    # Sound for every session: PipeWire, its PulseAudio front end, and the
    # session manager that connects devices.
    install -d "$user/sockets.target.wants" "$user/pipewire.service.wants"
    ln -s ../pipewire.socket "$user/sockets.target.wants/pipewire.socket"
    ln -s ../pipewire-pulse.socket "$user/sockets.target.wants/pipewire-pulse.socket"
    ln -s ../wireplumber.service "$user/pipewire.service.wants/wireplumber.service"

    # Sending files over Bluetooth: the session's OBEX daemon, started over
    # D-Bus by this alias.
    ln -s obex.service "$user/dbus-org.bluez.obex.service"

    # On a desktop NetworkManager runs the network, which is what GNOME's
    # network settings talk to. This file sorts before joe-base's rule and
    # tells systemd-networkd to leave wired interfaces alone.
    install -d "$DESTDIR/usr/lib/systemd/network"
    cat > "$DESTDIR/usr/lib/systemd/network/70-joe-desktop.network" <<'EOT'
[Match]
Type=ether
Kind=!*

[Link]
Unmanaged=yes
EOT

    # Default applications. GNOME's own list (gnome-mimeapps.list, from
    # gnome-session) names its browser and document viewer, which are not
    # what is installed; entries for programs that do not exist are skipped
    # and this list is consulted next.
    install -d "$DESTDIR/usr/share/applications"
    {
        echo '[Default Applications]'
        local type
        for type in text/html application/xhtml+xml x-scheme-handler/http x-scheme-handler/https; do
            echo "$type=firefox.desktop"
        done
        for type in application/pdf application/x-bzpdf application/x-gzpdf application/x-xzpdf application/x-ext-pdf; do
            echo "$type=org.gnome.Evince.desktop"
        done
    } > "$DESTDIR/usr/share/applications/mimeapps.list"

    # What is pinned to the dash for a new account. GNOME's default names
    # mostly applications that are not installed.
    install -d "$DESTDIR/usr/share/glib-2.0/schemas"
    cat > "$DESTDIR/usr/share/glib-2.0/schemas/20_joe-desktop.gschema.override" <<'EOT'
[org.gnome.shell]
favorite-apps=['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Calculator.desktop']
EOT
}
