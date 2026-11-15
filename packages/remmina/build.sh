# Not in the book: the newest upstream release, built with CMake; the options
# are upstream's (CMakeLists.txt, plugins/CMakeLists.txt).
build() {
    mkdir build
    cd build
    # Plugins: RDP (FreeRDP 3), VNC (libvncclient), SSH and SFTP (libssh,
    # VTE 2.91), the keyring (libsecret), and the always-built "exec".
    # Off:
    # - News, usage statistics and tips, which all contact remmina.org.
    # - Avahi: Remmina needs avahi-ui-gtk3, which the avahi recipe does not
    #   build.
    # - WWW and Azure AD log-in for RDP (WebKitGTK), SPICE (spice-gtk),
    #   gtk-vnc, X2Go (pyhoca-cli), KWallet, the tray icon (libappindicator),
    #   sso-mib, the KDE output-order protocol: no recipes.
    # - The Python plugin wrapper, and the kiosk session (a GNOME session
    #   that runs only Remmina).
    # - The icon, MIME and desktop caches: rebuilt by triggers.
    # CMAKE_SKIP_INSTALL_RPATH: upstream sets an $ORIGIN rpath that nothing
    # installed in /usr needs.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D WITH_FREERDP3=ON \
        -D WITH_LIBVNCSERVER=ON \
        -D WITH_LIBSSH=ON \
        -D WITH_VTE=ON \
        -D WITH_LIBSECRET=ON \
        -D WITH_CUPS=ON \
        -D WITH_GCRYPT=ON \
        -D WITH_AVAHI=OFF \
        -D WITH_NEWS=OFF \
        -D WITH_STATS=OFF \
        -D WITH_TIP=OFF \
        -D WITH_WWW=OFF \
        -D WITH_RDP_AUTH_AAD=OFF \
        -D WITH_SSO_MIB=OFF \
        -D WITH_SPICE=OFF \
        -D WITH_GVNC=OFF \
        -D WITH_X2GO=OFF \
        -D WITH_KF5WALLET=OFF \
        -D WITH_PYTHONLIBS=OFF \
        -D WITH_KIOSK_SESSION=OFF \
        -D HAVE_LIBAPPINDICATOR=OFF \
        -D ENABLE_KDE_OUTPUT_ORDER_V1=OFF \
        -D WITH_ICON_CACHE=OFF \
        -D WITH_UPDATE_DESKTOP_DB=OFF \
        -D WITH_MANPAGES=ON \
        -D WITH_TRANSLATIONS=ON \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
