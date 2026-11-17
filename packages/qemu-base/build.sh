# Following the book's qemu page, with Arch Linux's qemu-base package set:
# only the x86_64 and i386 system emulators (no user-mode emulation), the
# tools, the guest agent and the bridge helper, and no graphical user
# interface of its own. Guests are shown through SPICE or VNC (virt-manager,
# virt-viewer), -display dbus or the curses text console.
build() {
    mkdir -p build
    cd build

    # --without-default-features turns every optional feature off unless it
    # is named here, so nothing is picked up merely because it is in the
    # build root. What is on:
    #   kvm, tcg                  hardware virtualization; TCG as fallback
    #   tools, guest-agent        qemu-img, qemu-io, qemu-nbd,
    #                             qemu-storage-daemon, qemu-pr-helper,
    #                             qemu-vmsr-helper, qemu-edid, qemu-ga
    #   spice, vnc (jpeg, png,    remote displays (VNC with SASL
    #   sasl), dbus-display,      authentication); opengl and virglrenderer
    #   curses, opengl,           give guests an accelerated virtio-gpu
    #   virglrenderer             (also vhost-user-gpu), shown by SPICE or
    #                             -display dbus (and qemu-vnc over D-Bus)
    #   slirp, passt, l2tpv3,     network backends; vhost for in-kernel and
    #   vhost-*                   vhost-user devices and VDUSE exports
    #   curl, libssh, fuse,       http(s)/ssh images, FUSE exports, the image
    #   block formats, bzip2,     formats qemu-img converts, compressed
    #   lzo, zstd, snappy         dumps and migration
    #   linux-aio                 native asynchronous block I/O
    #   gnutls                    TLS and all cryptography (not nettle or
    #                             libgcrypt as well)
    #   usb-redir, libusb         USB redirection (SPICE) and pass-through
    #   alsa, pa, pipewire        audio (SPICE audio comes with spice)
    #   seccomp, cap-ng, attr,    -sandbox, virtio-9p (virtfs), PAM and
    #   auth-pam, keyring,        keyring secrets, TPM emulation (swtpm),
    #   tpm, libudev, fdt         host device lookup, device trees
    # What is off: GTK, SDL and Cocoa interfaces (and gettext, VTE, xkbcommon
    # with them; the keymaps ship pre-generated); io_uring and NUMA;
    # Ceph, GlusterFS, iSCSI and NFS images; libcacard smartcards, U2F; capstone,
    # libdw, BPF and AF_XDP; Xen and the other hypervisors; Rust devices;
    # and the documentation, which needs sphinx_rtd_theme (so no manual
    # pages either).
    ../configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libexecdir=/usr/libexec \
        --docdir=/usr/share/doc/qemu-$PKG_VERSION \
        --target-list=x86_64-softmmu,i386-softmmu \
        --disable-download \
        --without-default-features \
        --disable-docs \
        --enable-kvm \
        --enable-tcg \
        --enable-tools \
        --enable-guest-agent \
        --enable-attr \
        --enable-auth-pam \
        --enable-cap-ng \
        --enable-seccomp \
        --enable-malloc-trim \
        --enable-stack-protector \
        --enable-iconv \
        --enable-gio \
        --enable-dbus-display \
        --enable-qemu-vnc \
        --enable-pixman \
        --enable-vnc \
        --enable-vnc-jpeg \
        --enable-vnc-sasl \
        --enable-png \
        --enable-spice \
        --enable-spice-protocol \
        --enable-opengl \
        --enable-virglrenderer \
        --enable-curses \
        --enable-slirp \
        --enable-slirp-smbd \
        --enable-passt \
        --enable-l2tpv3 \
        --enable-vhost-kernel \
        --enable-vhost-net \
        --enable-vhost-user \
        --enable-vhost-crypto \
        --enable-vhost-vdpa \
        --enable-vhost-user-blk-server \
        --enable-libvduse \
        --enable-vduse-blk-export \
        --enable-virtfs \
        --enable-multiprocess \
        --enable-tpm \
        --enable-hv-balloon \
        --enable-replication \
        --enable-colo-proxy \
        --enable-bochs \
        --enable-cloop \
        --enable-dmg \
        --enable-qcow1 \
        --enable-qed \
        --enable-parallels \
        --enable-vdi \
        --enable-vhdx \
        --enable-vmdk \
        --enable-vpc \
        --enable-vvfat \
        --enable-bzip2 \
        --enable-lzo \
        --enable-zstd \
        --enable-snappy \
        --enable-linux-aio \
        --enable-curl \
        --enable-libssh \
        --enable-fuse \
        --enable-fuse-lseek \
        --enable-gnutls \
        --disable-nettle \
        --disable-gcrypt \
        --enable-keyring \
        --enable-libkeyutils \
        --enable-libudev \
        --enable-libusb \
        --enable-usb-redir \
        --enable-alsa \
        --enable-pa \
        --enable-pipewire \
        --audio-drv-list=pipewire,pa,alsa \
        --enable-fdt=system
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install

    # The book's shorthand for the native emulator.
    ln -s qemu-system-x86_64 "$DESTDIR/usr/bin/qemu"

    # The book makes the bridge helper set-uid root for the kvm group only
    # (4750 root:kvm); files are owned by root here, so it is set-uid for
    # everyone and /etc/qemu/bridge.conf alone decides which bridges a user
    # may attach to, as on Arch Linux.
    chmod 4755 "$DESTDIR/usr/libexec/qemu-bridge-helper"

    # Fedora's default: unprivileged (qemu:///session) guests may join
    # libvirt's default NAT network, virbr0, and nothing else.
    install -d "$DESTDIR/etc/qemu"
    cat > "$DESTDIR/etc/qemu/bridge.conf" << "EOF"
# Bridges qemu-bridge-helper lets unprivileged users attach guests to
# (qemu-bridge-helper is set-uid root). One "allow BRIDGE" per line;
# "allow all" allows every bridge. See qemu-bridge-helper.c.
allow virbr0
EOF

    # Upstream's units, none enabled. qemu-guest-agent.service is meant to
    # run inside a guest, bound to the agent's virtio channel.
    local unit
    for unit in qemu-guest-agent.service qemu-pr-helper.service qemu-pr-helper.socket \
                qemu-vmsr-helper.service qemu-vmsr-helper.socket; do
        install -Dm644 ../contrib/systemd/$unit "$DESTDIR/usr/lib/systemd/system/$unit"
    done
}
