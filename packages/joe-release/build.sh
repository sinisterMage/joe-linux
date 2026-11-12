package() {
    install -d "$DESTDIR/usr/lib" "$DESTDIR/etc"
    cat > "$DESTDIR/usr/lib/os-release" <<EOT
NAME="joe Linux"
ID=joe
PRETTY_NAME="joe Linux $PKG_VERSION"
VERSION="$PKG_VERSION"
VERSION_ID=$PKG_VERSION
BUILD_ID=$PKG_RELEASE
EOT
    ln -s ../usr/lib/os-release "$DESTDIR/etc/os-release"
    printf 'joe Linux %s \\n \\l\n\n' "$PKG_VERSION" > "$DESTDIR/etc/issue"
}
