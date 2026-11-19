# What turns the desktop into the live session of the installation medium
# (image/live.zon). The medium's root is a compressed read-only image with a
# writable layer in memory over it, and nothing on it is kept, so:
#
# - a user, liveuser, is logged in automatically (GDM's side of that is the
#   image's overlay, image/overlays/live: gdm owns /etc/gdm/custom.conf). The
#   account has no password and may do anything through doas and polkit
#   without one, as on other distributions' live media. doas reads only
#   /etc/doas.conf, which is opendoas's, so its rule is added to that file
#   at boot, and only then ("!": not by the trigger that runs tmpfiles.d
#   when the image is assembled), so the medium's root image holds the file
#   as packaged and the installer copies it from there unchanged;
# - the first-run setup is not offered: liveuser's session is marked as set
#   up, and GDM only starts gnome-initial-setup when no account exists;
# - the installer opens when the session starts, and is first in the dash;
# - the screen does not lock, since there is no password to unlock it with,
#   and the machine does not suspend while it is idle;
# - what only makes sense on an installed system is masked: dave's sealing
#   (fs-verity is not available on the live root, and the installed system
#   seals itself), the deferred upgrade at shutdown, and growing the root
#   partition, of which there is none.
package() {
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/joe-live.conf" <<'EOT'
u liveuser 1000:999 "Live session user" /home/liveuser /bin/bash
m liveuser wheel
EOT
    cat > "$DESTDIR/usr/lib/tmpfiles.d/joe-live.conf" <<'EOT'
d /home/liveuser 0700 liveuser users -
d /home/liveuser/.config 0700 liveuser users -
f /home/liveuser/.config/gnome-initial-setup-done 0644 liveuser users - yes
w+! /etc/doas.conf - - - - permit nopass liveuser\n
EOT

    install -d "$DESTDIR/usr/share/polkit-1/rules.d"
    cat > "$DESTDIR/usr/share/polkit-1/rules.d/49-joe-live.rules" <<'EOT'
// The live session's user may do anything without being asked for a
// password: the account has none, and nothing on the medium is kept.
polkit.addRule(function(action, subject) {
    if (subject.user == "liveuser")
        return polkit.Result.YES;
});
EOT

    install -d "$DESTDIR/usr/share/glib-2.0/schemas"
    cat > "$DESTDIR/usr/share/glib-2.0/schemas/30_joe-live.gschema.override" <<'EOT'
[org.gnome.desktop.screensaver]
lock-enabled=false

[org.gnome.desktop.lockdown]
disable-lock-screen=true

[org.gnome.desktop.session]
idle-delay=uint32 0

[org.gnome.settings-daemon.plugins.power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'

[org.gnome.shell]
favorite-apps=['org.joelinux.Installer.desktop', 'firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop']
EOT

    install -d "$DESTDIR/etc/xdg/autostart"
    cat > "$DESTDIR/etc/xdg/autostart/org.joelinux.Installer.desktop" <<'EOT'
[Desktop Entry]
Type=Application
Name=Install joe Linux
Exec=joe-installer
Icon=org.joelinux.Installer
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOT

    local system="$DESTDIR/etc/systemd/system" unit
    install -d "$system"
    for unit in dave-seal dave-finalize systemd-repart systemd-growfs-root; do
        ln -s /dev/null "$system/$unit.service"
    done
}
