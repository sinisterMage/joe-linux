# Not in the book: the newest upstream release, built with CMake as
# INSTALL.md describes. The source tarball carries .version, so it builds as
# a release, not a snapshot.
build() {
    mkdir build
    cd build
    # - KPXC_FEATURE_DOCS: the HTML guides and the manual pages are written
    #   in AsciiDoc and need asciidoctor.
    # - KPXC_FEATURE_UPDATES: upstream's switch for managed distributions;
    #   updates come from dave. Downloading favicons (KPXC_FEATURE_NETWORK)
    #   stays.
    # - Browser integration, the SSH agent and the Secret Service provider
    #   are built, as are Auto-Type for X11 programs (WITH_X11) and for
    #   Wayland, through the desktop portal.
    # - zxcvbn is not packaged; the bundled copy is used.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D KEEPASSXC_DIST_TYPE=Native \
        -D WITH_TESTS=OFF \
        -D WITH_GUI_TESTS=OFF \
        -D WITH_X11=ON \
        -D WITH_CCACHE=OFF \
        -D KPXC_MINIMAL=OFF \
        -D KPXC_FEATURE_BROWSER=ON \
        -D KPXC_FEATURE_SSHAGENT=ON \
        -D KPXC_FEATURE_FDOSECRETS=ON \
        -D KPXC_FEATURE_NETWORK=ON \
        -D KPXC_FEATURE_UPDATES=OFF \
        -D KPXC_FEATURE_DOCS=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
