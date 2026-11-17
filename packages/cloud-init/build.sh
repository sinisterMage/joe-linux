# Not in the book: the newest upstream release, built with meson as its
# meson.build says.
prepare() {
    # The units, the generator and cloud.cfg are rendered for a "variant"
    # read from the build root's os-release. cloud-init knows nothing of
    # joe, would fall back to Ubuntu (apt, netplan, a default user named
    # ubuntu) and its generator would look for ds-identify where no one
    # installs it. Arch Linux is the closest distribution it knows:
    # systemd, sshd, the wheel group, network through NetworkManager or
    # systemd-networkd, ds-identify in /usr/lib/cloud-init. (Its package
    # and locale-gen handling do not apply to joe; neither runs unless
    # cloud-config asks for packages or a locale.)
    sed -i 's/default=platform\["variant"\]/default="arch"/' tools/render-template
}

build() {
    mkdir build
    cd build
    # libexecdir=lib: /usr/lib/cloud-init, where the Arch variant's
    # generator runs ds-identify from.
    meson setup .. \
        --prefix=/usr \
        --libexecdir=lib \
        --sysconfdir=/etc \
        --buildtype=release \
        -D init_system=systemd \
        -D bash_completion=true \
        -D disable_sshd_keygen=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # The Arch variant names the default user arch.
    sed -i -e 's/^    name: arch$/    name: joe/' \
           -e 's/^    gecos: arch Cloud User$/    gecos: joe Cloud User/' \
        "$DESTDIR/etc/cloud/cloud.cfg"
    grep -q '^    name: joe$' "$DESTDIR/etc/cloud/cloud.cfg"

    # meson copies the modules into site-packages without compiling them.
    # cloud-init runs as root, and Python would otherwise write its own,
    # unsealed byte code there on first boot.
    python3 -m compileall -q -s "$DESTDIR" -p / "$DESTDIR"/usr/lib/python3.*/site-packages/cloudinit

    # Upstream's units are installed and none is enabled. Its generator
    # (cloud-init-generator) runs ds-identify at every boot and pulls
    # cloud-init.target in only when a datasource is found (a cloud's
    # metadata service, a NoCloud seed disk, ...), so on other machines
    # cloud-init does nothing; /etc/cloud/cloud-init.disabled or
    # cloud-init=disabled on the kernel command line turn it off entirely.
}
