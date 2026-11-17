# Not in the book: the newest upstream release, built as its README says.
prepare() {
    # The archive is the repository at the tag, without configure.
    ./autogen.sh
}

build() {
    # pppd 2.5 at its packaged path, routes through /proc/net/route,
    # openfortivpn@.service. configure would otherwise look for these on
    # the build machine. The resolvconf it would find is systemd's
    # (resolvectl), which openfortivpn cannot drive the way it drives
    # openresolv, so it is compiled in but off by default: --use-resolvconf=1
    # turns it on, and otherwise openfortivpn edits /etc/resolv.conf when
    # set-dns is on.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --with-pppd=/usr/sbin/pppd \
        --disable-legacy-pppd \
        --enable-proc \
        --with-resolvconf=/usr/sbin/resolvconf \
        --disable-resolvconf \
        --with-systemdsystemunitdir=/usr/lib/systemd/system
    make
}

package() {
    # Installs /etc/openfortivpn/config (0600), every setting commented out,
    # and openfortivpn@.service, which is not enabled: an instance NAME
    # reads /etc/openfortivpn/NAME.conf.
    make DESTDIR="$DESTDIR" install
}
