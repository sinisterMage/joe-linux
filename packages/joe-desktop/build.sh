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
}
