# Not in the book: the newest upstream release, built as its README says,
# with the units Arch Linux writes for it (upstream ships none).
prepare() {
    patch -Np1 -i /recipe/icu-link.patch
    patch -Np1 -i /recipe/glib-free.patch
    # configure appends -Werror to CFLAGS unconditionally; with GCC 16 the
    # sources warn about discarded const qualifiers (strchr and friends
    # return const pointers for const arguments in C23), which then fail
    # the build. Arch Linux patches the casts in; keeping them warnings has
    # the same effect.
    sed -i '/^CFLAGS="\$CFLAGS -Werror"$/d' configure.ac
    autoreconf -fiv
}

build() {
    # Off, because what they need is not packaged: VGAuth (xmlsec1), which
    # vSphere's guest operations authenticate through; the guest
    # customization plugin deployPkg (libmspack); the containerinfo plugin
    # (gRPC, containerd). Service discovery, the Salt minion scripts and
    # libappmonitor are off by default upstream. The kernel modules are in
    # the kernel (vmw_balloon, vmw_vmci, vmw_vsock_vmci_transport, vmwgfx).
    # The documentation needs doxygen, the tests CUnit.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-udev-rules-dir=/usr/lib/udev/rules.d \
        --without-kernel-modules \
        --with-x \
        --with-gtk3 \
        --without-gtk4 \
        --with-gtkmm3 \
        --with-fuse=fuse3 \
        --with-pam \
        --with-tirpc \
        --with-icu \
        --without-dnet \
        --without-ssl \
        --without-xmlsec1 \
        --enable-resolutionkms \
        --enable-vmwgfxctrl \
        --enable-multimon \
        --disable-vgauth \
        --disable-deploypkg \
        --disable-containerinfo \
        --disable-servicediscovery \
        --disable-salt-minion \
        --disable-libappmonitor \
        --disable-docs \
        --disable-tests \
        --disable-static
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # Opens /dev/uinput and the vmblock control file for vmware-user, as
    # root (Arch Linux and Fedora install it set-uid root too). Upstream's
    # XDG autostart entry runs it in every desktop session; vmware-user
    # (vmtoolsd -n vmusr) exits at once outside a VMware guest.
    chmod 4755 "$DESTDIR/usr/bin/vmware-user-suid-wrapper"

    # Upstream's generic PAM file names pam_unix_auth.so and
    # pam_unix_acct.so, which Linux-PAM no longer has; use the system's
    # stacks, as the other services here do.
    cat > "$DESTDIR/etc/pam.d/vmtoolsd" << "EOF"
# Authenticates guest operations requested through VMware Tools.
auth      include     system-auth
account   include     system-account
EOF

    # Arch Linux's units, neither enabled. Both only start in a VMware
    # guest. vmware-vmblock-fuse blocks drag-and-drop file access until the
    # transfer is complete.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/vmtoolsd.service" << "EOF"
[Unit]
Description=Open Virtual Machine Tools (VMware Tools)
ConditionVirtualization=vmware
After=display-manager.service

[Service]
ExecStart=/usr/bin/vmtoolsd

[Install]
WantedBy=multi-user.target
EOF
    cat > "$DESTDIR/usr/lib/systemd/system/vmware-vmblock-fuse.service" << "EOF"
[Unit]
Description=Open Virtual Machine Tools (vmware-vmblock-fuse)
ConditionVirtualization=vmware

[Service]
Type=simple
RuntimeDirectory=vmblock-fuse
RuntimeDirectoryMode=755
ExecStart=/usr/bin/vmware-vmblock-fuse -d -f -o subtype=vmware-vmblock,default_permissions,allow_other /run/vmblock-fuse

[Install]
WantedBy=multi-user.target
EOF
}
