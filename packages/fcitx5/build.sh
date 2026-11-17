# Not in the book: the newest upstream release, built with CMake as its
# README says.
build() {
    # The event loop and D-Bus are systemd's (sd-event, sd-bus). The KDE
    # Plasma window management protocol is the copy in the source tree (KDE's
    # plasma-wayland-protocols has no recipe), and so is the Yoga layout
    # library, which upstream does not expect to be installed. The testing
    # addons are only for the test suite, which is not run.
    #
    # Fcitx 5 starts in every desktop session through its XDG autostart file
    # (/etc/xdg/autostart/org.fcitx.Fcitx5.desktop), as upstream installs
    # it: installing the package is the choice of Fcitx 5 over IBus.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_INSTALL_SYSCONFDIR=/etc \
        -D CMAKE_BUILD_TYPE=Release \
        -D EVENT_LOOP_BACKEND=systemd \
        -D ENABLE_TEST=OFF \
        -D ENABLE_TESTING_ADDONS=OFF \
        -D ENABLE_DOC=OFF \
        -D ENABLE_ENCHANT=ON \
        -D ENABLE_X11=ON \
        -D ENABLE_WAYLAND=ON \
        -D ENABLE_DBUS=ON \
        -D ENABLE_KEYBOARD=ON \
        -D ENABLE_EMOJI=ON \
        -D ENABLE_LIBUUID=ON \
        -D ENABLE_XDGAUTOSTART=ON \
        -D BUILD_SPELL_DICT=ON \
        -D USE_SYSTEM_YOGA=OFF \
        -D USE_SYSTEM_PLASMA_WAYLAND_PROTOCOLS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
