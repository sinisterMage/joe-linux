# Not in the book: the newest upstream release, built from its tarball as
# upstream's own packaging (tools/cockpit.spec, tools/arch/PKGBUILD) builds
# it. The web pages are the tarball's prebuilt dist/ (its files are dated
# after package-lock.json and the sources, so make does not try to rebuild
# them).
#
# No system accounts: since version 330 cockpit-ws, cockpit-tls and the
# socket users are systemd DynamicUser services, and cockpit-session is not
# set-uid; it is started as root by cockpit-session@.service through
# /run/cockpit/session.
build() {
    # Administrators are the members of wheel (joe-filesystem); the
    # session's PATH leaves out /sbin and /bin, which are links to /usr.
    # cockpit-client (a GTK/WebKit window) and the SELinux policy are off,
    # as they are by default; so is connecting to other hosts from the
    # login page (AllowMultiHost), as upstream now prefers.
    # --disable-doc: with documentation on, make renders the HTML guide
    # again with Asciidoctor (its rule depends on dist/); the guide is not
    # shipped anyway, and the manual pages are installed prebuilt below,
    # as tools/cockpit.spec does where Asciidoctor is missing.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libexecdir=/usr/libexec \
        --with-systemdunitdir=/usr/lib/systemd/system \
        --with-pamdir=/usr/lib/security \
        --with-admin-group=wheel \
        --with-default-session-path=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin \
        --disable-cockpit-client \
        --disable-selinux-policy \
        --disable-multihost \
        --disable-doc
    make
}

package() {
    # Installs the programs, the pages in /usr/share/cockpit, cockpit-bridge
    # as a Python package (pip, offline, from upstream's own wheel
    # builder), pam_ssh_add.so, the units, tmpfiles.d/cockpit-ws.conf (the
    # issue files in /run/cockpit) and the polkit action. It also links
    # /etc/issue.d/cockpit.issue and /etc/motd.d/cockpit to
    # /run/cockpit/issue, which says how to start cockpit, or where it
    # listens once cockpit.socket is running. No unit is enabled:
    # "systemctl enable --now cockpit.socket" starts the console on port
    # 9090.
    make DESTDIR="$DESTDIR" install

    local page
    for page in doc/output/man/*.[158]; do
        install -Dm644 "$page" "$DESTDIR/usr/share/man/man${page##*.}/${page##*/}"
    done

    # Pages that cannot apply to joe: SELinux troubleshooting (joe has no
    # SELinux) and software updates and applications through PackageKit
    # (joe's packages are dave's). The other pages that need software joe
    # may not have (NetworkManager, udisks, kdump, sos) hide themselves
    # when it is missing, by the conditions in their manifests.
    rm -r "$DESTDIR/usr/share/cockpit/selinux" \
        "$DESTDIR/usr/share/cockpit/packagekit" \
        "$DESTDIR/usr/share/cockpit/apps" \
        "$DESTDIR/usr/share/metainfo/org.cockpit_project.cockpit_selinux.metainfo.xml"

    # Root may not log in to the console, as upstream's packages set up on
    # first installation (administrators log in as themselves and use
    # sudo or pkexec).
    cat > "$DESTDIR/etc/cockpit/disallowed-users" << "EOF2"
# List of users which are not allowed to login to Cockpit
root
EOF2
    chmod 644 "$DESTDIR/etc/cockpit/disallowed-users"

    # Upstream's tools/cockpit.pam in joe's layout (packages/linux-pam): the
    # system-* stacks for Fedora's password-auth, and without the SELinux,
    # pam_sepermit and postlogin lines. pam_ssh_add (installed above)
    # unlocks the user's SSH keys with the login password; pam_loginuid
    # and pam_systemd are in system-session. pam_env and pam_limits, as for
    # the other logins (packages/openssh), because the console runs a shell
    # and commands for the user.
    install -d "$DESTDIR/etc/pam.d"
    cat > "$DESTDIR/etc/pam.d/cockpit" << "EOF2"
# Begin /etc/pam.d/cockpit

auth      include     system-auth
auth      optional    pam_ssh_add.so

# Users who may not log in to Cockpit; root by default.
account   required    pam_listfile.so item=user sense=deny file=/etc/cockpit/disallowed-users onerr=succeed
account   required    pam_nologin.so
account   include     system-account

password  include     system-password

session   optional    pam_keyinit.so force revoke
session   optional    pam_ssh_add.so
session   required    pam_env.so
session   required    pam_limits.so
session   include     system-session

# End /etc/pam.d/cockpit
EOF2
    chmod 644 "$DESTDIR/etc/pam.d/cockpit"
}
