# Following the book's network-manager-applet page.
build() {
    mkdir build
    cd build
    # As in the book: no AppIndicator (libayatana-appindicator is not
    # packaged; the applet uses the XEmbed tray), no SELinux, and no team
    # editor: joe's NetworkManager is built without teamd support
    # (-D teamdctl=false), so jansson would serve nothing. WWAN support
    # (ModemManager) is on.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D appindicator=no \
        -D wwan=true \
        -D selinux=false \
        -D team=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
