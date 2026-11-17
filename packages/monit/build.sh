# Not in the book: the newest upstream release, built as its README says.
# The tarball carries the generated parser and scanner and the manual page,
# so bison, flex and pod2man are not needed.
build() {
    # Everything configure would otherwise decide by probing is stated:
    # TLS through OpenSSL, PAM, zlib, IPv6 (configure would test it by
    # opening a socket), and the pid file in /run.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --with-piddir=/run \
        --with-ssl \
        --with-pam \
        --with-zlib \
        --with-ipv6 \
        --with-largefiles
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The control file, where its manual looks for it after ~/.monitrc, with
    # the mode monit insists on (it refuses a control file others can read).
    # It is upstream's example: check every 30 seconds, log to syslog, and
    # the web interface on localhost:2812 for the user admin, password
    # monit, which the administrator is expected to change. No PAM service
    # file is shipped (upstream has none), so "allow @group" is refused
    # by /etc/pam.d/other until one is written.
    install -Dm600 monitrc "$DESTDIR/etc/monitrc"

    # Upstream's unit, made from system/startup/monit.service.in by
    # configure; not enabled.
    install -Dm644 system/startup/monit.service "$DESTDIR/usr/lib/systemd/system/monit.service"
    install -Dm644 system/bash/monit "$DESTDIR/usr/share/bash-completion/completions/monit"
}
