build() {
    # mount.cifs would go to /sbin, which belongs to joe-filesystem as a
    # link to usr/sbin.
    export ROOTSBINDIR=/usr/sbin
    # The book's switch, and the optional parts stated: Kerberos (MIT krb5)
    # for cifs.upcall, libcap-ng to drop capabilities in mount.cifs, the
    # manual pages with docutils' rst2man. cifs.idmap and get/setcifsacl
    # need libwbclient from Samba and are left out, so that mounting a share
    # does not depend on Samba. No PAM module, as in the book.
    ./configure --prefix=/usr \
        --disable-pam \
        --enable-cifsupcall \
        --enable-cifscreds \
        --disable-cifsidmap \
        --disable-cifsacl \
        --enable-smbinfo \
        --enable-pythontools \
        --enable-systemd \
        --enable-man \
        --with-libcap-ng=yes
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
