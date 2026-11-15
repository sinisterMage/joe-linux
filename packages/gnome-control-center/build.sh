prepare() {
    # The Printers panel links Samba's libsmbclient, to browse for printers
    # shared over SMB, whenever it is installed; there is no option for it.
    # joe's desktop does not include Samba, so never look for it (network
    # printers are found over IPP).
    sed -i "s/dependency('smbclient', required: false)/dependency('', required: false)/" \
        panels/printers/meson.build
}

build() {
    mkdir build
    cd build
    # The book builds with the defaults. Stated here:
    # - snap (snapd) and malcontent (parental controls) do not exist.
    # - privileged_group: administrators are the members of wheel, as
    #   accountsservice and polkit are set up.
    # - Samba is looked for only by the Printers panel, which the patch
    #   removes; Kerberos is used for enterprise log-in in Users.
    # --wrap-mode=nodownload: gvc and libgxdp are shipped in the tarball;
    # nothing else may be fetched.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D ibus=true \
        -D location-services=enabled \
        -D privileged_group=wheel \
        -D snap=false \
        -D malcontent=false \
        -D ssh_socket_activation=false \
        -D documentation=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
