# Not in the book: the newest upstream release, built as its INSTALL says.
#
# postfix provides /usr/sbin/sendmail, so no sendmail link to msmtp is
# installed (upstream's make install makes none either); point a program at
# /usr/bin/msmtp, or link it from ~/bin, to have msmtp send its mail.
build() {
    # TLS through GnuTLS (upstream's default), IDN, libsecret, msmtpd.
    # Off: GNU SASL (no recipe; msmtp's own PLAIN, LOGIN, CRAM-MD5,
    # SCRAM-SHA-* and XOAUTH2/OAUTHBEARER are built in).
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --with-tls=gnutls \
        --with-libidn \
        --with-libsecret \
        --with-msmtpd \
        --without-libgsasl
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # Upstream's queueing wrappers (scripts/msmtpq): msmtpq queues mail
    # when offline and sends it later, msmtp-queue manages the queue.
    install -m755 scripts/msmtpq/msmtpq scripts/msmtpq/msmtp-queue "$DESTDIR/usr/bin/"
}
