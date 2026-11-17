# Not in the book: the newest upstream release, built as its README says.
#
# Only the NSS modules (libnss_mdns*.so.2) are installed. Nothing uses them
# until /etc/nsswitch.conf (glibc's) names one, and avahi-daemon is running.
# To resolve NAME.local through Avahi, put mdns_minimal before resolve on
# the hosts line:
#
#   hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns
#
# mdns4_minimal and mdns6_minimal do the same for one address family only;
# the variants without _minimal also look up names outside .local, as
# listed in /etc/mdns.allow (README.md).
build() {
    # configure's default prefix is empty, not /usr. Avahi's socket is
    # /run/avahi-daemon/socket. The unit tests are not built.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --runstatedir=/run \
        --disable-static \
        --disable-tests
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
