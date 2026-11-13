prepare() {
    # OpenSSL 4 made ASN1_STRING opaque (Beyond LFS).
    sed -e 's/\([->.a-zA-Z_]*\)->length/ASN1_STRING_length(\1)/' \
        -i lib/iolog/hostcheck.c
}

build() {
    # The first six switches are the book's. The rest state what configure
    # would otherwise decide from the build root: authentication through PAM,
    # OpenSSL and the system zlib for the log server and its client, no mail
    # (there is no sendmail), and the state directories. The tmpfiles.d file
    # creates /run/sudo/ts at boot; /var/lib/sudo is made by sudo itself the
    # first time it is needed.
    ./configure --prefix=/usr \
        --libexecdir=/usr/lib \
        --with-secure-path \
        --with-env-editor \
        --docdir=/usr/share/doc/sudo-1.9.17p2 \
        --with-passprompt="[sudo] password for %p: " \
        --with-pam \
        --enable-openssl \
        --enable-zlib \
        --without-sendmail \
        --with-rundir=/run/sudo \
        --with-vardir=/var/lib/sudo \
        --enable-tmpfiles.d=/usr/lib/tmpfiles.d
    make
}

package() {
    # Installs sudo set-uid root (4755), /etc/sudoers 0440 and /etc/sudoers.d
    # 0750, all owned by root, which is who runs this.
    make DESTDIR="$DESTDIR" install

    # Members of the administrators' group, wheel (gid 97, joe-filesystem),
    # may run anything after giving their own password. /etc/sudoers reads
    # this directory through its "@includedir /etc/sudoers.d" line.
    grep -qx '@includedir /etc/sudoers.d' "$DESTDIR/etc/sudoers"
    cat > "$DESTDIR/etc/sudoers.d/00-sudo" << "EOF"
Defaults secure_path="/usr/sbin:/usr/bin"
%wheel ALL=(ALL:ALL) ALL
EOF
    chmod 0440 "$DESTDIR/etc/sudoers.d/00-sudo"

    install -d "$DESTDIR/etc/pam.d"
    cat > "$DESTDIR/etc/pam.d/sudo" << "EOF"
# Begin /etc/pam.d/sudo

# include the default auth settings
auth      include     system-auth

# include the default account settings
account   include     system-account

# Set default environment variables for the service user
session   required    pam_env.so

# include system session defaults
session   include     system-session

# End /etc/pam.d/sudo
EOF
    chmod 644 "$DESTDIR/etc/pam.d/sudo"
}
