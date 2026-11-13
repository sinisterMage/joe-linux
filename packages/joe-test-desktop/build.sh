# Never install this on a real system. There is no installer and no first-run
# setup yet, so a demonstration image needs a user to log in as. The account
# has no password of its own: the virtual machine supplies one at boot through
# a systemd credential (passwd.plaintext-password.joe), or GDM's automatic
# login is used.
package() {
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/joe-test-desktop.conf" <<'EOT'
u joe 1000:999 "joe" /home/joe /bin/bash
m joe wheel
EOT
    cat > "$DESTDIR/usr/lib/tmpfiles.d/joe-test-desktop.conf" <<'EOT'
d /home/joe 0700 joe users -
EOT
}
