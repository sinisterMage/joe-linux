prepare() {
    # Fix an issue with deprecated schema entries.
    sed -e 's@/desktop/ibus@/org/freedesktop/ibus@g' \
        -i data/dconf/org.freedesktop.ibus.gschema.xml

    # GTK-Doc does not exist here: remove the references to it.
    sed '/docs/d;/GTK_DOC/d' -i Makefile.am configure.ac
}

build() {
    # The archive holds some generated headers that autogen.sh would
    # otherwise delete (SAVE_DIST_FILES), and configure is run by hand so
    # that autogen.sh does not choose compiler flags (NOCONFIGURE).
    SAVE_DIST_FILES=1 NOCONFIGURE=1 ./autogen.sh

    # GNOME Shell needs the IBus typelib to start and runs ibus-daemon
    # itself, as the panel; applications reach it through the compositor
    # (Wayland text input). So only the library, its introspection data, the
    # daemon, its dconf configuration service, the command line tool and the
    # simple (keyboard layout) engine are built. Left out, compared with the
    # book: the GTK 3 and GTK 4 input modules, the XIM server, ibus' own
    # Wayland client and GTK panel, ibus-setup, the notification support
    # that only the panel uses, and the Unicode dictionary, which needs the
    # Unicode Character Database (an extra download). --disable-gtk2,
    # --disable-appindicator and --disable-emoji-dict are the book's.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --enable-introspection=yes \
        --enable-vala=yes \
        --enable-dconf \
        --enable-engine \
        --enable-systemd-services \
        --disable-gtk2 \
        --disable-gtk3 \
        --disable-gtk4 \
        --disable-xim \
        --disable-wayland \
        --disable-ui \
        --disable-setup \
        --disable-libnotify \
        --disable-appindicator \
        --disable-emoji-dict \
        --disable-unicode-dict \
        --disable-tests

    # data/dconf lists the schema defaults with gsettings to write the
    # system database source; the memory backend answers that without a
    # running dconf service.
    GSETTINGS_BACKEND=memory make
}

package() {
    # With DESTDIR set, neither "dconf update" nor glib-compile-schemas run.
    make DESTDIR="$DESTDIR" install
}
