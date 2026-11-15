# Not in the book: the newest upstream release, built with meson as the
# project's Packaging wiki page describes. metadata.json lists GNOME Shell
# 46 to 51.
build() {
    mkdir build
    cd build
    # - The GSettings schema goes to /usr/share/glib-2.0/schemas, which is
    #   also where the extension looks for it (GSETTINGS_SCHEMA_DIR in
    #   config.js); glib's trigger compiles it there.
    # - gnome_shell_libdir: where GNOME Shell's private typelibs (Gvc) are,
    #   /usr/lib/gnome-shell.
    # - No Nautilus or Nemo extension (they need nautilus-python), no
    #   firewalld service, no installed tests.
    # - The native messaging manifests for the browser add-on are installed.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gnome_shell_libdir=/usr/lib \
        -D session_bus_services_dir=/usr/share/dbus-1/services \
        -D nautilus=false \
        -D nemo=false \
        -D firewalld=false \
        -D webextension=true \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
