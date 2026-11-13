build() {
    mkdir build
    cd build
    # The book only switches the tests off; the rest is stated here.
    # - portal_helper (the captive portal log-in window) needs WebKitGTK,
    #   which does not exist here.
    # - Manual pages are not built; the stylesheets are shipped ready-made,
    #   so sassc is not needed.
    # - Bluetooth has no build option: the shell looks for the
    #   GnomeBluetooth typelib when it starts and does without.
    # --wrap-mode=nodownload rather than nofallback: libshew and gvc are
    # subprojects shipped inside the tarball and must be used.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D systemd=true \
        -D networkmanager=true \
        -D camera_monitor=true \
        -D extensions_tool=true \
        -D extensions-tool:bash_completion=disabled \
        -D portal_helper=false \
        -D tests=false \
        -D man=false \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
