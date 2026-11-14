# The book's configuration, with its D-Bus interfaces: NetworkManager talks
# to wpa_supplicant over D-Bus and starts it on demand. No per-interface
# configuration is shipped; NetworkManager supplies the networks.
build() {
    cat > wpa_supplicant/.config <<'EOT'
CONFIG_BACKEND=file
CONFIG_CTRL_IFACE=y
CONFIG_DEBUG_FILE=y
CONFIG_DEBUG_SYSLOG=y
CONFIG_DEBUG_SYSLOG_FACILITY=LOG_DAEMON
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CONFIG_DRIVER_WIRED=y
CONFIG_EAP_GTC=y
CONFIG_EAP_LEAP=y
CONFIG_EAP_MD5=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_OTP=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_TLS=y
CONFIG_EAP_TTLS=y
CONFIG_IEEE8021X_EAPOL=y
CONFIG_IPV6=y
CONFIG_LIBNL32=y
CONFIG_PEERKEY=y
CONFIG_PKCS12=y
CONFIG_READLINE=y
CONFIG_SMARTCARD=y
CONFIG_WPS=y
CFLAGS += -I/usr/include/libnl3
CONFIG_CTRL_IFACE_DBUS=y
CONFIG_CTRL_IFACE_DBUS_NEW=y
CONFIG_CTRL_IFACE_DBUS_INTRO=y
EOT
    cd wpa_supplicant
    make BINDIR=/usr/sbin LIBDIR=/usr/lib
}

package() {
    cd wpa_supplicant
    install -d "$DESTDIR/usr/sbin" "$DESTDIR/usr/lib/systemd/system" "$DESTDIR/usr/share/dbus-1/system-services" \
        "$DESTDIR/usr/share/dbus-1/system.d"
    install -m755 wpa_cli wpa_passphrase wpa_supplicant "$DESTDIR/usr/sbin/"
    install -m644 systemd/*.service "$DESTDIR/usr/lib/systemd/system/"
    install -m644 dbus/fi.w1.wpa_supplicant1.service "$DESTDIR/usr/share/dbus-1/system-services/"
    # Where the D-Bus of this system reads vendor policy (the book uses /etc).
    install -m644 dbus/dbus-wpa_supplicant.conf "$DESTDIR/usr/share/dbus-1/system.d/wpa_supplicant.conf"
}
