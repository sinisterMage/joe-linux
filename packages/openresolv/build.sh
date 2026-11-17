# Not in the book: the newest upstream release, built as its README says.
#
# systemd already provides /usr/sbin/resolvconf (a link to resolvectl,
# which hands what it is given to systemd-resolved), and that is the
# resolvconf DHCP and VPN clients find. So openresolv's program is installed
# as /usr/sbin/openresolv, with its manual page as openresolv(8), and is
# used only by what is pointed at it explicitly (for instance on a system
# without systemd-resolved). Its subscribers, /etc/resolvconf.conf and its
# state in /run/resolvconf are its own and clash with nothing.
prepare() {
    # The subscribers call the program by its full path.
    sed -i 's:@SBINDIR@/resolvconf\b:@SBINDIR@/openresolv:g' *.in
}

build() {
    # A hand-written configure: these are the options it knows.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --sbindir=/usr/sbin \
        --libexecdir=/usr/libexec/openresolv \
        --rundir=/run \
        --mandir=/usr/share/man
    make
}

package() {
    # Manual pages would be installed read-only (0444).
    make DESTDIR="$DESTDIR" MANMODE=0644 install
    mv "$DESTDIR/usr/sbin/resolvconf" "$DESTDIR/usr/sbin/openresolv"
    mv "$DESTDIR/usr/share/man/man8/resolvconf.8" "$DESTDIR/usr/share/man/man8/openresolv.8"
}
