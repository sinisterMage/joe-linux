# Not in the book: the newest upstream release. Its README describes the
# configure script; it is built with the meson build upstream maintains
# alongside it, which does not install the manual pages, so package()
# does.
build() {
    mkdir build
    cd build
    # The run-time check only looks for ip, which is declared in depends.
    # The send-to extensions for Nautilus, Nemo and Caja need their
    # nautilus-python bindings and Thunar's needs Thunar, none of which is
    # packaged. blueman-mechanism.service is installed, not enabled; it is
    # started over D-Bus.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D runtime_deps_check=false \
        -D policykit=true \
        -D pulseaudio=true \
        -D sendto-plugins=[] \
        -D thunar-sendto=false
    ninja
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
    install -Dm644 -t "$DESTDIR/usr/share/man/man1" data/man/*.1
}
