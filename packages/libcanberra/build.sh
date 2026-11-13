prepare() {
    patch -Np1 -i "$SOURCES/libcanberra-0.30-wayland-1.patch"
}

build() {
    # Everything optional is stated so that the build root cannot change the
    # result: ALSA and GStreamer backends, the GTK 3 module and, with udev,
    # canberra-boot and its systemd units; no GTK 2, PulseAudio, OSS or tdb
    # (the cache of looked-up sounds).
    ./configure --prefix=/usr \
        --disable-static \
        --enable-alsa \
        --enable-gstreamer \
        --enable-null \
        --enable-gtk3 \
        --enable-udev \
        --disable-oss \
        --disable-pulse \
        --disable-gtk \
        --disable-tdb \
        --disable-lynx \
        --disable-gtk-doc \
        --with-systemdsystemunitdir=/usr/lib/systemd/system
    make
}

package() {
    make DESTDIR="$DESTDIR" docdir=/usr/share/doc/libcanberra-0.30 install
}
