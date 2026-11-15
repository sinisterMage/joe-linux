prepare() {
    # meson_post_install.py gives /etc/polkit-1/rules.d to the polkitd group
    # when that user exists where it runs, which in the build root it does
    # once polkit has been installed there, and chown is not possible in the
    # build. The ownership comes from polkit's tmpfiles.d file at boot; the
    # script still makes pkexec and polkit-agent-helper-1 set-uid.
    sed -i 's/^    polkitd_gid = pwd.getpwnam(polkitd_user).pw_gid$/    polkitd_gid = None/' meson_post_install.py
    if grep -q 'getpwnam' meson_post_install.py; then
        echo "meson_post_install.py still looks the polkitd user up" >&2
        return 1
    fi
}

build() {
    mkdir build
    cd build
    # duktape is the only JavaScript engine left. PAM authenticates and
    # sessions come from systemd-logind. os_type=lfs selects the PAM include
    # names that linux-pam ships (system-auth, system-account, ...); it would
    # otherwise be guessed from files in /etc. The uid is the book's.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D session_tracking=logind \
        -D authfw=pam \
        -D os_type=lfs \
        -D polkitd_user=polkitd \
        -D polkitd_uid=27 \
        -D introspection=true \
        -D gettext=true \
        -D man=false \
        -D gtk_doc=false \
        -D examples=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # The install script sets these only when it runs as real root.
    chmod 4755 "$DESTDIR/usr/bin/pkexec" \
        "$DESTDIR/usr/lib/polkit-1/polkit-agent-helper-1"

    # Administrator rules are readable by root and polkitd only. The package
    # holds the directory as root:root; the group is set at boot by upstream's
    # usr/lib/tmpfiles.d/polkit-tmpfiles.conf
    # (d /etc/polkit-1/rules.d 0750 root polkitd).
    install -d -m 750 "$DESTDIR/etc/polkit-1/rules.d"
    chmod 750 "$DESTDIR/etc/polkit-1/rules.d"

    # Upstream's sysusers.d file, with the account exactly as the book
    # creates it (groupadd -g 27, useradd -u 27 -d /etc/polkit-1).
    cat > "$DESTDIR/usr/lib/sysusers.d/polkit.conf" <<'EOT'
g polkitd 27
u polkitd 27:27 "PolicyKit Daemon Owner" /etc/polkit-1 /usr/bin/false
EOT
}
