prepare() {
    # These manual pages are provided by man-pages.
    find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
    find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;

    # Hash passwords with yescrypt, keep mailboxes in /var/mail, and leave the
    # /bin and /sbin symlinks out of the default PATH.
    sed -e 's:#ENCRYPT_METHOD SHA512:ENCRYPT_METHOD YESCRYPT:' \
        -e 's:/var/spool/mail:/var/mail:' \
        -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
        -i etc/login.defs
}

build() {
    ./configure --sysconfdir=/etc \
        --disable-static \
        --with-bcrypt \
        --with-yescrypt \
        --without-libbsd \
        --disable-logind \
        --with-group-name-max-length=32
    make
}

package() {
    # exec_prefix=/usr: configure leaves it empty, which would put login, su,
    # nologin and libsubid in /bin, /sbin and /lib.
    # The set-uid programs get mode 4755 from "make install" itself; nothing
    # is chowned and setcap is not used (no --with-fcaps, no --with-tcb).
    make exec_prefix=/usr DESTDIR="$DESTDIR" install
    make -C man DESTDIR="$DESTDIR" install-man

    # Defaults for useradd: what "useradd -D --gid 999" writes, with the
    # creation of mail spool files turned off. Group 999 is "users".
    install -dm755 "$DESTDIR/etc/default"
    cat > "$DESTDIR/etc/default/useradd" << "EOF"
# useradd defaults file
GROUP=999
GROUPS=
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
SKEL=/etc/skel
USRSKEL=/usr/etc/skel
CREATE_MAIL_SPOOL=no
BTRFS_SUBVOLUME_HOME=no
BTRFS_SUBVOLUME_SYSTEM=no
LOG_INIT=yes
EOF
}
