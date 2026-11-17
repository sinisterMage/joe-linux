# Not in the book: the newest upstream release, built with meson as its
# docs/compiling.rst says.
build() {
    mkdir build
    cd build
    # Every feature is named, so nothing is picked up merely because it is
    # in the build root. On: the QEMU driver (guests run as libvirt-qemu,
    # see package()), the test driver, the remote driver, both the modular
    # daemons (virtqemud, virtnetworkd, ...) and the monolithic libvirtd,
    # virtual networks (nftables first, then iptables), network filters
    # (libpcap), host interfaces and node devices through udev, secrets,
    # and the storage pools whose tools exist: directories, file systems
    # (local and NFS), SCSI and multipath (libdevmapper). polkit decides
    # who may manage the system daemons; members of the libvirt group may
    # (upstream's rule). When firewalld is running, virtual networks join
    # its libvirt zone (over D-Bus; nothing is linked). The NSS module
    # resolves guest names (libnss_libvirt), and ssh-proxy reaches guests
    # over vsock. Remote clients may authenticate through Cyrus SASL. The
    # documentation is built for its manual pages and for the API
    # descriptions (/usr/share/libvirt/api) libvirt-python is generated
    # from; the HTML pages are dropped with usr/share/doc.
    #
    # Off, because what they need is not packaged: LVM pools (lvm2 is built
    # as device-mapper only), disk pools (parted), iSCSI, Gluster, Ceph RBD,
    # ZFS and Virtuozzo storage, netcf, NUMA (numactl, numad), nbdkit,
    # sanlock, audit, SELinux and AppArmor, DTrace, Wireshark. Also off:
    # the Xen, LXC, bhyve, Cloud Hypervisor, ESX, Hyper-V, OpenVZ,
    # VirtualBox, VMware and Virtuozzo drivers (and curl and FUSE, which
    # only ESX, Cloud Hypervisor and LXC use), and virt-login-shell, which
    # is set-uid root and only for LXC.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D system=true \
        -D runstatedir=/run \
        -D unitdir=/usr/lib/systemd/system \
        -D sysusersdir=/usr/lib/sysusers.d \
        -D init_script=systemd \
        -D rpath=disabled \
        -D git_werror=disabled \
        -D expensive_tests=disabled \
        -D tests=disabled \
        -D docs=enabled \
        -D nls=enabled \
        -D bash_completion=enabled \
        -D attr=enabled \
        -D blkid=enabled \
        -D capng=enabled \
        -D json_c=enabled \
        -D libnl=enabled \
        -D libpcap=enabled \
        -D libssh=enabled \
        -D libssh2=enabled \
        -D pciaccess=enabled \
        -D polkit=enabled \
        -D readline=enabled \
        -D udev=enabled \
        -D curl=disabled \
        -D fuse=disabled \
        -D apparmor=disabled \
        -D apparmor_profiles=disabled \
        -D audit=disabled \
        -D glusterfs=disabled \
        -D libiscsi=disabled \
        -D netcf=disabled \
        -D numactl=disabled \
        -D openwsman=disabled \
        -D sanlock=disabled \
        -D sasl=enabled \
        -D selinux=disabled \
        -D wireshark_dissector=disabled \
        -D libvirtd=enabled \
        -D driver_libvirtd=enabled \
        -D driver_remote=enabled \
        -D driver_qemu=enabled \
        -D qemu_user=libvirt-qemu \
        -D qemu_group=libvirt-qemu \
        -D driver_test=enabled \
        -D driver_interface=enabled \
        -D driver_network=enabled \
        -D driver_nodedev=enabled \
        -D driver_nwfilter=enabled \
        -D driver_secret=enabled \
        -D driver_storage=enabled \
        -D storage_dir=enabled \
        -D storage_fs=enabled \
        -D storage_scsi=enabled \
        -D storage_mpath=enabled \
        -D storage_lvm=disabled \
        -D storage_disk=disabled \
        -D storage_iscsi=disabled \
        -D storage_iscsi_direct=disabled \
        -D storage_gluster=disabled \
        -D storage_rbd=disabled \
        -D storage_vstorage=disabled \
        -D storage_zfs=disabled \
        -D driver_bhyve=disabled \
        -D driver_ch=disabled \
        -D driver_esx=disabled \
        -D driver_hyperv=disabled \
        -D driver_libxl=disabled \
        -D driver_lxc=disabled \
        -D driver_openvz=disabled \
        -D driver_vbox=disabled \
        -D driver_vmware=disabled \
        -D driver_vz=disabled \
        -D secdriver_apparmor=disabled \
        -D secdriver_selinux=disabled \
        -D dtrace=disabled \
        -D firewalld=enabled \
        -D firewalld_zone=enabled \
        -D host_validate=enabled \
        -D login_shell=disabled \
        -D nss=enabled \
        -D numad=disabled \
        -D nbdkit=disabled \
        -D nbdkit_config_default=disabled \
        -D pm_utils=disabled \
        -D ssh_proxy=enabled \
        -D sysctl_config=enabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # Upstream's units and sockets (virtqemud, virtnetworkd, virtstoraged,
    # ..., virtlogd, virtlockd, libvirtd, libvirt-guests) are installed and
    # none is enabled. The default NAT network (virbr0) is marked to start
    # with the network driver, as upstream installs it
    # (/etc/libvirt/qemu/networks/autostart/default.xml).

    # Fixed ids, because /var is shared between deployments. Upstream's
    # files give the libvirt group (who may manage the system daemons, see
    # the polkit rule) no fixed id and name the QEMU account qemu; guests
    # run as libvirt-qemu here, as on Arch Linux and Debian. It is in the
    # kvm group for /dev/kvm.
    cat > "$DESTDIR/usr/lib/sysusers.d/libvirt.conf" << "EOF"
g libvirt 63
EOF
    cat > "$DESTDIR/usr/lib/sysusers.d/libvirt-qemu.conf" << "EOF"
g libvirt-qemu 64
u libvirt-qemu 64:libvirt-qemu "libvirt QEMU user" - -
m libvirt-qemu kvm
EOF

    # The state directories upstream's install creates under /var (which
    # is not packaged); the daemons make the ones under /run themselves,
    # and the QEMU driver hands its directories to libvirt-qemu when it
    # starts. Logs, secrets and the network state stay private to root;
    # images can be reached but not listed.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/libvirt.conf" << "EOF"
d /var/cache/libvirt 0711 root root -
d /var/cache/libvirt/qemu 0750 libvirt-qemu libvirt-qemu -
d /var/lib/libvirt 0755 root root -
d /var/lib/libvirt/boot 0711 root root -
d /var/lib/libvirt/dnsmasq 0755 root root -
d /var/lib/libvirt/filesystems 0711 root root -
d /var/lib/libvirt/images 0711 root root -
d /var/lib/libvirt/network 0700 root root -
d /var/lib/libvirt/qemu 0751 libvirt-qemu libvirt-qemu -
d /var/lib/libvirt/secrets 0700 root root -
d /var/lib/libvirt/swtpm 0711 root root -
d /var/log/libvirt 0700 root root -
d /var/log/libvirt/qemu 0700 root root -
EOF
}
