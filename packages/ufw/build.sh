# Not in the book: the newest upstream release, built as its README says
# (setup.py install, whose own install step puts every file in place).
prepare() {
    # The boot helper and its functions go to /usr/lib/ufw, not /lib/ufw
    # (as in Arch Linux).
    sed -i "s|real_statedir = os.path.join('/lib', 'ufw')|real_statedir = os.path.join('/usr/lib', 'ufw')|" setup.py
    grep -q "os.path.join('/usr/lib', 'ufw')" setup.py
}

package() {
    # Installs /usr/sbin/ufw and the ufw module, ufw-init in /usr/lib/ufw,
    # the default rules and settings in /etc/ufw and /etc/default/ufw
    # (pristine copies of the rules in /usr/share/ufw/iptables), the
    # application profiles in /etc/ufw/applications.d, translations and
    # manual pages. ufw keeps the rules added with "ufw allow" and the like
    # in /etc/ufw/user*.rules. The before.init and after.init hooks there
    # run only if made executable.
    python3 setup.py install --root="$DESTDIR" --prefix=/usr

    install -Dm644 shell-completion/bash "$DESTDIR/usr/share/bash-completion/completions/ufw"

    # Upstream's example unit, with the helper's path above. Not enabled;
    # "ufw enable" also needs to be run once.
    install -d "$DESTDIR/usr/lib/systemd/system"
    sed 's|/lib/ufw/|/usr/lib/ufw/|g' doc/systemd.example > "$DESTDIR/usr/lib/systemd/system/ufw.service"
    grep -q '^ExecStart=/usr/lib/ufw/ufw-init start' "$DESTDIR/usr/lib/systemd/system/ufw.service"
}
