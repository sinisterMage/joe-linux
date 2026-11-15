prepare() {
    grep -rl '^#!.*python$' | xargs sed -i '1s/python/&3/'
}

build() {
    mkdir build
    cd build
    # Wired networking with the built-in DHCP client. DNS goes to
    # systemd-resolved, which NetworkManager detects at run time from the
    # /etc/resolv.conf symlink (rc-manager auto), so neither resolvconf nor
    # netconfig is used.
    #
    # Wi-Fi goes through wpa_supplicant, over D-Bus (not iwd, and not the
    # old wireless extensions).
    #
    # Mobile broadband goes through ModemManager, and Bluetooth dial-up
    # networking through BlueZ.
    #
    # Switched off because what they need does not exist: ofono, PPP,
    # Open vSwitch and nm-cloud-setup (jansson), teamd, nmtui (newt),
    # SELinux, audit, CLAT (libbpf), firewalld, dhcpcd, Qt examples. NBFT
    # stays off as in the book. The paths of iptables, nft and dnsmasq are
    # given so that the build root is not searched for them; they are used
    # only for connection sharing, if ever installed.
    #
    # jansson has no switch: it is used if the build root has it.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D systemdsystemunitdir=/usr/lib/systemd/system \
        -D udev_dir=/usr/lib/udev \
        -D dbus_conf_dir=/usr/share/dbus-1/system.d \
        -D kernel_firmware_dir=/usr/lib/firmware \
        -D modprobe=/usr/sbin/modprobe \
        -D iptables=/usr/sbin/iptables \
        -D ip6tables=/usr/sbin/ip6tables \
        -D nft=/usr/sbin/nft \
        -D dnsmasq=/usr/sbin/dnsmasq \
        -D session_tracking=systemd \
        -D session_tracking_consolekit=false \
        -D suspend_resume=systemd \
        -D systemd_journal=true \
        -D polkit=true \
        -D polkit_agent_helper_1=/usr/lib/polkit-1/polkit-agent-helper-1 \
        -D crypto=nss \
        -D libpsl=true \
        -D concheck=true \
        -D nmcli=true \
        -D readline=libreadline \
        -D config_dhcp_default=internal \
        -D dhcpcd=no \
        -D config_dns_rc_manager_default=auto \
        -D resolvconf=no \
        -D netconfig=no \
        -D introspection=true \
        -D vapi=true \
        -D wifi=true \
        -D iwd=false \
        -D wext=false \
        -D modem_manager=true \
        -D ofono=false \
        -D bluez5_dun=true \
        -D ppp=false \
        -D ovs=false \
        -D teamdctl=false \
        -D nmtui=false \
        -D nm_cloud_setup=false \
        -D nbft=false \
        -D clat=false \
        -D selinux=false \
        -D libaudit=no \
        -D firewalld_zone=false \
        -D ifcfg_rh=false \
        -D ifupdown=false \
        -D qt=false \
        -D docs=false \
        -D man=false \
        -D tests=no
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # The tarball's ready-made manual pages, less those of parts that were
    # not built.
    local file section
    for file in ../man/*.[1578]; do
        case ${file##*/} in
            nmtui.1 | nm-openvswitch.7 | nm-cloud-setup.8 | nm-settings-ifcfg-rh.5) continue ;;
        esac
        section=${file##*.}
        install -vdm 755 "$DESTDIR/usr/share/man/man$section"
        install -vm 644 "$file" "$DESTDIR/usr/share/man/man$section/"
    done

    install -vdm 755 "$DESTDIR/etc/NetworkManager/conf.d"
    cat > "$DESTDIR/etc/NetworkManager/NetworkManager.conf" << "EOF"
[main]
plugins=keyfile
EOF

    cat > "$DESTDIR/etc/NetworkManager/conf.d/polkit.conf" << "EOF"
[main]
auth-polkit=true
EOF

    # The book's no-dns-update.conf (dns=none) is not installed: it would
    # keep NetworkManager from handing DNS servers to systemd-resolved.

    # Members of netdev may configure connections without authenticating.
    # The group has the book's id (groupadd -g 86).
    install -vdm 755 "$DESTDIR/usr/lib/sysusers.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/networkmanager.conf" <<'EOT'
g netdev 86
EOT

    install -vdm 755 "$DESTDIR/usr/share/polkit-1/rules.d"
    cat > "$DESTDIR/usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules" << "EOF"
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 && subject.isInGroup("netdev")) {
        return polkit.Result.YES;
    }
});
EOF

    # /var/lib/NetworkManager (leases, secret key, timestamps) is not
    # packaged.
    install -vdm 755 "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/networkmanager.conf" <<'EOT'
d /var/lib/NetworkManager 0700 root root -
EOT
}
