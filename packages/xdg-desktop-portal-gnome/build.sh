build() {
    mkdir build
    cd build
    # libgxdp is bundled in the tarball as a subproject, hence nodownload
    # rather than nofallback.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D systemd=enabled
    ninja
}

package() {
    cd build
    # The book compiles the GSettings schemas here; that is glib's trigger.
    DESTDIR="$DESTDIR" ninja install
}
