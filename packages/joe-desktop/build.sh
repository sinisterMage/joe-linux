# What makes the installed components a desktop: which services start, and
# who manages the network. Services are enabled by shipping the links
# `systemctl enable` would create, because packages have no install scripts.
package() {
    local system="$DESTDIR/usr/lib/systemd/system" user="$DESTDIR/usr/lib/systemd/user"

    # graphical.target, systemd's default, starts whatever is the display manager.
    install -d "$system/multi-user.target.wants"
    ln -s gdm.service "$system/display-manager.service"
    local unit
    for unit in NetworkManager accounts-daemon upower udisks2; do
        ln -s "../$unit.service" "$system/multi-user.target.wants/$unit.service"
    done

    # Sound for every session: PipeWire, its PulseAudio front end, and the
    # session manager that connects devices.
    install -d "$user/sockets.target.wants" "$user/pipewire.service.wants"
    ln -s ../pipewire.socket "$user/sockets.target.wants/pipewire.socket"
    ln -s ../pipewire-pulse.socket "$user/sockets.target.wants/pipewire-pulse.socket"
    ln -s ../wireplumber.service "$user/pipewire.service.wants/wireplumber.service"

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
