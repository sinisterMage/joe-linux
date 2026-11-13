build() {
    mkdir build
    cd build
    # Only the client side is built: libpulse, libpulse-simple,
    # libpulse-mainloop-glib and pactl and friends, which GNOME's volume
    # control code links and which talk to pipewire-pulse. The book also
    # builds the daemon (with gdbm, which does not exist here); pipewire
    # replaces it, so the daemon's options do not apply.
    # - x11: only lets clients find a server through X root window
    #   properties; the session is Wayland.
    # - asyncns, fftw, GTK (an old equaliser front end), valgrind and the
    #   OSS wrapper are not used; doxygen and the manual pages (XML::Parser)
    #   are not built.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D daemon=false \
        -D client=true \
        -D doxygen=false \
        -D man=false \
        -D tests=false \
        -D ipv6=true \
        -D dbus=enabled \
        -D glib=enabled \
        -D systemd=enabled \
        -D x11=disabled \
        -D asyncns=disabled \
        -D fftw=disabled \
        -D gtk=disabled \
        -D valgrind=disabled \
        -D oss-output=disabled \
        -D bashcompletiondir=no \
        -D zshcompletiondir=no
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
