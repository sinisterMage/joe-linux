prepare() {
    # The version script reads the version from the name of the source
    # directory, which is not what the build sandbox calls it.
    printf '#!/bin/sh\necho %s\n' "$PKG_VERSION" > generate-version.sh
}

build() {
    mkdir build
    cd build
    # The tests need python-dbusmock; the documentation needs xmlto and
    # gtk-doc.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D admin_group=wheel \
        -D elogind=false \
        -D libxcrypt=true \
        -D create_homed=false \
        -D introspection=true \
        -D vapi=true \
        -D docbook=false \
        -D gtk_doc=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # joe's administrators are the members of wheel, which is also polkit's
    # own default, so the book's rule file naming another group is not needed.

    # /var is not packaged. The unit's StateDirectory= makes the top
    # directory; the two below it have modes of their own.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/accountsservice.conf" <<'EOT'
d /var/lib/AccountsService 0775 root root -
d /var/lib/AccountsService/icons 0775 root root -
d /var/lib/AccountsService/users 0700 root root -
EOT
}
