build() {
    mkdir build
    cd build
    # Everything optional is stated so that the build root cannot change the
    # result. Compared with the book:
    # - ENABLE_OAUTH2_WEBKITGTK(4): WebKitGTK does not exist here, so there is
    #   no built-in OAuth2 log-in window; accounts that need one are set up
    #   through GNOME Online Accounts, which uses the web browser.
    # - WITH_KRB5=ON: MIT Kerberos exists (the book builds without it).
    # - ENABLE_INSTALLED_TESTS, ENABLE_TESTS, ENABLE_EXAMPLES: not shipped.
    # - WITH_OPENLDAP, WITH_LIBDB, WITH_PHONENUMBER: do not exist here.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D SYSCONF_INSTALL_DIR=/etc \
        -D ENABLE_GTK=ON \
        -D ENABLE_GTK4=ON \
        -D ENABLE_OAUTH2_WEBKITGTK=OFF \
        -D ENABLE_OAUTH2_WEBKITGTK4=OFF \
        -D ENABLE_GOA=ON \
        -D ENABLE_WEATHER=ON \
        -D ENABLE_CANBERRA=ON \
        -D ENABLE_SMIME=ON \
        -D ENABLE_INTROSPECTION=ON \
        -D ENABLE_VALA_BINDINGS=ON \
        -D ENABLE_INSTALLED_TESTS=OFF \
        -D ENABLE_TESTS=OFF \
        -D ENABLE_EXAMPLES=OFF \
        -D ENABLE_GTK_DOC=OFF \
        -D ENABLE_GI_DOCGEN=OFF \
        -D WITH_KRB5=ON \
        -D WITH_OPENLDAP=OFF \
        -D WITH_LIBDB=OFF \
        -D WITH_PHONENUMBER=OFF \
        -W no-author -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
