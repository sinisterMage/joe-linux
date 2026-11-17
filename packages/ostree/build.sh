# Not in the book: the newest upstream release, built with the configure
# script in its release tarball. joe Linux does not boot from OSTree
# deployments; this is the library Flatpak keeps its installations in.
build() {
    # HTTP is fetched with curl, so neither libsoup is linked (both would be
    # picked up when found). There is no SELinux, and composefs has no
    # recipe. The built-in GRUB configuration generator keeps a file out of
    # /etc/grub.d; joe boots with systemd-boot. The boot units it installs
    # only act on systems booted with ostree= on the kernel command line.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libdir=/usr/lib \
        --disable-static \
        --with-curl \
        --without-soup \
        --without-soup3 \
        --with-crypto=openssl \
        --without-ed25519-libsodium \
        --with-gpgme \
        --without-composefs \
        --with-libarchive \
        --without-selinux \
        --without-smack \
        --with-avahi \
        --with-libmount \
        --with-libsystemd \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-systemdsystemgeneratordir=/usr/lib/systemd/system-generators \
        --without-dracut \
        --without-mkinitcpio \
        --with-builtin-grub2-mkconfig \
        --enable-rofiles-fuse \
        --enable-introspection=yes \
        --enable-man \
        --disable-gtk-doc \
        --disable-installed-tests
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
