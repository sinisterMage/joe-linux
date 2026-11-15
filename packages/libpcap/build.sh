build() {
    # The book's build with its optional dependencies stated: Bluetooth
    # (BlueZ), Wi-Fi monitor mode (libnl) and D-Bus capture on; RDMA
    # (rdma-core) and remote capture off.
    ./configure --prefix=/usr \
        --enable-ipv6 \
        --with-libnl \
        --enable-bluetooth \
        --enable-dbus \
        --enable-usb \
        --disable-rdma \
        --disable-remote
    # The static library is not installed.
    sed -i '/INSTALL_DATA.*libpcap.a\|RANLIB.*libpcap.a/ s/^/#/' Makefile
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
