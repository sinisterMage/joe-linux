# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # Switched off: the X11 drawing module and the X example programs
    # (m17n-edit, m17n-view), which GNOME on Wayland has no use for; and,
    # having no recipes, OTF shaping (libotf) and the GD drawing module.
    # The Thai word segmenters (libthai, wordcut) and ispell have no
    # recipes and no switch: configure does not find them.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-gui \
        --without-x \
        --without-libotf \
        --without-gd \
        --with-fontconfig
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
