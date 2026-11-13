build() {
    mkdir build
    cd build
    # No ModemManager (3G, CDMA and modem GPS sources) and no Avahi (NMEA
    # source). The service runs as root, as upstream and the book have it.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D gtk-doc=false \
        -D nmea-source=false \
        -D 3g-source=false \
        -D cdma-source=false \
        -D modem-gps-source=false \
        -D wifi-source=true \
        -D ip-source=true \
        -D static-source=true \
        -D compass=true \
        -D enable-backend=true \
        -D libgeoclue=true \
        -D introspection=true \
        -D vapi=true \
        -D demo-agent=true \
        -D dbus-srv-user=root
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # The book's /etc/geoclue/conf.d/90-lfs-google.conf is not installed: it
    # carries the Linux From Scratch project's own Google API key. Wi-Fi
    # positioning uses upstream's default service (beaconDB).
}
