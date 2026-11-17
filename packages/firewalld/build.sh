# Not in the book: the newest upstream release, built as its README says.
#
# The daemon (firewalld) and its command-line clients (firewall-cmd,
# firewall-offline-cmd). Its graphical tools are left out: firewall-applet
# needs PyQt, which is not packaged, and firewall-config, a GTK 3
# program, belongs in a package of its own rather than in a firewall's
# dependencies.
build() {
    # Paths configure would otherwise look up on the build machine. ebtables
    # is iptables' nftables variant; ipset is not packaged, and the nftables
    # back end keeps its sets in nftables itself.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-schemas-compile \
        --with-systemd-unitdir=/usr/lib/systemd/system \
        --with-bashcompletiondir=/usr/share/bash-completion/completions \
        --with-zshcompletiondir=/usr/share/zsh/site-functions \
        --with-iptables=/usr/sbin/iptables \
        --with-iptables-restore=/usr/sbin/iptables-restore \
        --with-ip6tables=/usr/sbin/ip6tables \
        --with-ip6tables-restore=/usr/sbin/ip6tables-restore \
        --with-ebtables=/usr/sbin/ebtables \
        --with-ebtables-restore=/usr/sbin/ebtables-restore \
        --with-ipset=/usr/sbin/ipset \
        PYTHON=/usr/bin/python3 \
        KILL=/usr/bin/kill \
        MODPROBE=/usr/sbin/modprobe \
        RMMOD=/usr/sbin/rmmod \
        SYSCTL=/usr/sbin/sysctl
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The graphical tools (see the top), with their data, icons, desktop
    # entries, settings schema and manual pages. /usr/share/firewalld holds
    # nothing else but upstream's test suite, which is not installed either.
    rm "$DESTDIR/usr/bin/firewall-applet" "$DESTDIR/usr/bin/firewall-config"
    rm -r "$DESTDIR/usr/share/firewalld"
    rm -r "$DESTDIR/usr/share/icons" "$DESTDIR/usr/share/applications" \
        "$DESTDIR/usr/share/metainfo" "$DESTDIR/usr/share/glib-2.0" \
        "$DESTDIR/etc/xdg" "$DESTDIR/etc/firewall"
    rm "$DESTDIR/usr/share/man/man1/firewall-applet.1" "$DESTDIR/usr/share/man/man1/firewall-config.1"

    # The installation creates the configuration directories, which hold
    # local zones, services and so on, readable by all; as Fedora ships
    # them, they are for root only.
    chmod 750 "$DESTDIR/etc/firewalld" "$DESTDIR"/etc/firewalld/*/

    # make install copies the Python modules without compiling them. The
    # daemon runs as root, which must not write byte code of its own
    # (it would be unsealed), so compile them here; the build driver makes
    # the files hash-based.
    local site
    site=$(python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))')
    python3 -m compileall -q -s "$DESTDIR" "$DESTDIR$site/firewall"
}
