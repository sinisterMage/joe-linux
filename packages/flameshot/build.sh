# Not in the book: the newest upstream release, built with CMake as its
# README says, the way distributions build it.
#
# CMakeLists.txt would clone Qt-Color-Widgets with FetchContent. The copy
# given as a source is put where upstream's Flatpak puts it,
# external/Qt-Color-Widgets, which CMakeLists.txt uses instead.
# KDSingleApplication is joe's own package, not a bundled copy.
prepare() {
    mkdir -p external/Qt-Color-Widgets
    tar -xzf "$SOURCES/Qt-Color-Widgets-5d52e907e50dc88cf969b41cea44665ff6c475b1.tar.gz" \
        -C external/Qt-Color-Widgets --strip-components=1
}

# - The Wayland clipboard (USE_WAYLAND_CLIPBOARD) needs KDE Frameworks'
#   KGuiAddons, which joe does not package.
# - The update check is switched off: updates come from dave.
# - The Qt Designer plugin of Qt-Color-Widgets is not built; joe's Qt has no
#   Designer.
# - ccache, which is in the build root, is not used (ENABLE_CACHE).
# - The tarball is not a git checkout; the version string gets the commit of
#   the v15.0.0 tag through GIT_HASH.
build() {
    GIT_HASH=f4f2e4e cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_CACHE=OFF \
        -D USE_KDSINGLEAPPLICATION=ON \
        -D USE_BUNDLED_KDSINGLEAPPLICATION=OFF \
        -D USE_WAYLAND_CLIPBOARD=OFF \
        -D DISABLE_UPDATE_CHECKER=ON \
        -D ENABLE_IMGUR=OFF \
        -D QTCOLORWIDGETS_DESIGNER_PLUGIN=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
    # Qt-Color-Widgets' install rules add its static library, headers and
    # CMake files; it is compiled into flameshot, which installs nothing in
    # these directories itself.
    rm -rf "$DESTDIR/usr/include" "$DESTDIR/usr/lib"
}
