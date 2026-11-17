# Not in the book (Beyond LFS no longer carries it): the newest upstream
# release, built with meson as its README says. GNOME Contacts needs it.
build() {
    mkdir build
    cd build
    # Backends: evolution-data-server (address books), key-file and dummy
    # (always built) and BlueZ (phone books over D-Bus; links nothing
    # beyond evolution-data-server).
    # - telepathy_backend: needs telepathy-glib and dbus-glib; Telepathy has
    #   no recipe.
    # - ofono_backend: talks to the oFono telephony daemon, which has no
    #   recipe.
    # - profiling: needs libsysprof-capture, which has no recipe.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D eds_backend=true \
        -D bluez_backend=true \
        -D ofono_backend=false \
        -D telepathy_backend=false \
        -D zeitgeist=false \
        -D import_tool=true \
        -D inspect_tool=true \
        -D profiling=false \
        -D tests=false \
        -D installed_tests=false \
        -D docs=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
