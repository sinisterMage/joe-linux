# Not in the book: the newest upstream release, built as its README and
# INSTALL say.
#
# pppd is not set-uid root (upstream's make install does not make it so,
# and Arch Linux leaves it that way): it is started by root, by
# NetworkManager or by the units of what uses it (openfortivpn and the
# like), or by an administrator with pon.
build() {
    # Callback control (CBCP) and multilink are off by default upstream and
    # turned on, as in Arch Linux; the Microsoft extensions, EAP-TLS, PEAP,
    # IPv6CP and plugins are on by default. EAP-TLS checks certificates
    # against /etc/ssl/certs.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --runstatedir=/run \
        --disable-static \
        --enable-systemd \
        --enable-cbcp \
        --enable-multilink \
        --with-openssl=/usr \
        --with-pcap=/usr \
        --with-pam=yes \
        --with-system-ca-path=/etc/ssl/certs
    make
}

package() {
    # pppd, chat, pppdump and pppstats in /usr/sbin, the plugins in
    # /usr/lib/pppd/2.5.5, the headers plugins are built against, and the
    # example configuration as /etc/ppp/*.example.
    make DESTDIR="$DESTDIR" install
    install -d "$DESTDIR/etc/ppp/peers"

    # pon, poff and plog start, stop and show the log of a connection
    # described in /etc/ppp/peers. (lcp_rtt_dump and autopppd, Perl
    # scripts for debugging and dial-on-demand, are left out.)
    install -m755 scripts/pon scripts/poff scripts/plog "$DESTDIR/usr/sbin/"
    install -Dm644 scripts/pon.1 "$DESTDIR/usr/share/man/man1/pon.1"

    # The login option checks peers' names and passwords with PAM.
    install -d "$DESTDIR/etc/pam.d"
    cat > "$DESTDIR/etc/pam.d/ppp" << "EOF2"
# Begin /etc/pam.d/ppp
# Used by pppd's "login" option to check a peer's name and password.

auth      include     system-auth
account   include     system-account
session   include     system-session

# End /etc/pam.d/ppp
EOF2

    # A unit for a connection described in /etc/ppp/peers/NAME, as Arch
    # Linux ships it (upstream ships none): ppp@NAME.service. pppd reports
    # readiness once the link is up. Not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/ppp@.service" << "EOF2"
[Unit]
Description=PPP link to %I
Before=network.target

[Service]
Type=notify
ExecStart=/usr/sbin/pppd call %I nodetach nolog up_sdnotify

[Install]
WantedBy=multi-user.target
EOF2

    # pppd makes /run/pppd itself; the connect-errors log is in /var/log/ppp.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/ppp.conf" << "EOF2"
d /var/log/ppp 0755 root root -
EOF2
}
