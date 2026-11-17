# Not in the book: the newest upstream release, built with CMake as its
# README says.
build() {
    # The built-in updater is off: joe's packages are updated by dave.
    # Shell integration: the GNOME Files sidebar through libcloudproviders
    # and the overlay icons are built; the Nautilus, Nemo and Caja
    # extensions are Python scripts for nautilus-python and its forks,
    # which are not packaged, and the Dolphin plugin needs KDE's KIO.
    # Optional KDE frameworks (KDBusAddons, KGuiAddons) and OpenVFS have no
    # recipes. The desktop user unit is installed, not enabled.
    cmake -B build \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D KDE_INSTALL_LIBDIR=lib \
        -D KDE_INSTALL_LIBEXECDIR=libexec \
        -D KDE_INSTALL_USE_QT_SYS_PATHS=ON \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_TESTING=OFF \
        -D BUILD_UPDATER=OFF \
        -D ENABLE_CLANG_TIDY=OFF \
        -D BUILD_SHELL_INTEGRATION=ON \
        -D BUILD_SHELL_INTEGRATION_ICONS=ON \
        -D BUILD_SHELL_INTEGRATION_NAUTILUS=OFF \
        -D BUILD_SHELL_INTEGRATION_DOLPHIN=OFF \
        -D INSTALL_SYSTEMD=ON \
        -D CMAKE_DISABLE_FIND_PACKAGE_KF6DBusAddons=ON \
        -D CMAKE_DISABLE_FIND_PACKAGE_KF6GuiAddons=ON \
        -D CMAKE_DISABLE_FIND_PACKAGE_OpenVFS=ON \
        -W no-dev
    cmake --build build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
