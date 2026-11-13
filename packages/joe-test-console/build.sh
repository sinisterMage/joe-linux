# Never install this on a real system: it logs root in on the serial console
# without asking for a password. The automated tests drive the system through
# that console, and an image has no other way in until there is an installer
# that sets a password.
#
# It is a package, not something the image builder writes, so that its files
# are sealed like any others; a root shell would not read an unsealed profile.
package() {
    install -d "$DESTDIR/usr/lib/systemd/system/serial-getty@ttyS0.service.d"
    cat > "$DESTDIR/usr/lib/systemd/system/serial-getty@ttyS0.service.d/autologin.conf" <<'EOT'
[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --autologin root --noclear --keep-baud 115200 %I dumb
EOT

    # A fixed prompt the test harness can recognise, and no terminal tricks.
    install -d "$DESTDIR/usr/lib/joe/profile.d"
    cat > "$DESTDIR/usr/lib/joe/profile.d/test-console.sh" <<'EOT'
if [ "$(id -u)" -eq 0 ] && [ "$(tty 2>/dev/null)" = /dev/ttyS0 ]; then
    PS1='joe# '
    TERM=dumb
    unset PROMPT_COMMAND
    bind 'set enable-bracketed-paste off' 2>/dev/null
fi
EOT
}
