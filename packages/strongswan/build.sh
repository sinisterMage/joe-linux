# Not in the book: the newest upstream release, built as its INSTALL and
# the documentation's "Installation" page say.
#
# The daemon is charon-systemd, configured with swanctl (/etc/swanctl) over
# the vici interface; strongswan.service starts it and loads every
# connection, and is not enabled. The legacy stroke interface, ipsec
# starter and ipsec.conf stay off, as upstream now builds by default.
build() {
    # Plugins beyond upstream's defaults, close to Arch Linux's selection.
    # Off, besides upstream's other non-default plugins: IKEv1 (deprecated,
    # off by default upstream; --enable-ikev1 adds it), MySQL, the
    # NetworkManager back end (NetworkManager-strongswan is not packaged),
    # TPM 2.0 (tpm2-tss), the 3GPP2 EAP-AKA back end (GMP), DNSSEC lookups
    # (unbound plugin), the Python and Ruby vici bindings, and the
    # high-availability plugin (it needs the ClusterIP target, which Linux
    # no longer has).
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libexecdir=/usr/libexec \
        --with-piddir=/run \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-capabilities=libcap \
        --disable-static \
        --enable-systemd \
        --enable-swanctl \
        --disable-stroke \
        --disable-ikev1 \
        --enable-openssl \
        --enable-aesni \
        --enable-chapoly \
        --enable-sha3 \
        --enable-mgf1 \
        --enable-ml \
        --enable-curl \
        --enable-ldap \
        --enable-sql \
        --enable-sqlite \
        --enable-attr-sql \
        --enable-agent \
        --enable-pkcs11 \
        --enable-dnscert \
        --enable-eap-identity \
        --enable-eap-md5 \
        --enable-eap-gtc \
        --enable-eap-mschapv2 \
        --enable-eap-tls \
        --enable-eap-ttls \
        --enable-eap-peap \
        --enable-eap-dynamic \
        --enable-eap-radius \
        --enable-eap-sim \
        --enable-eap-sim-file \
        --enable-eap-aka \
        --enable-eap-simaka-pseudonym \
        --enable-eap-simaka-reauth \
        --enable-xauth-eap \
        --enable-xauth-pam \
        --enable-xauth-noauth \
        --enable-ext-auth \
        --enable-radattr \
        --enable-dhcp \
        --enable-farp \
        --enable-unity \
        --enable-bypass-lan \
        --enable-connmark \
        --enable-forecast \
        --enable-counters \
        --enable-cmd \
        --disable-mysql \
        --disable-nm \
        --disable-tpm \
        --disable-unbound \
        --disable-eap-aka-3gpp2 \
        --disable-python-wheels \
        --disable-ruby-gems \
        --disable-perl-cpan \
        --disable-selinux
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
