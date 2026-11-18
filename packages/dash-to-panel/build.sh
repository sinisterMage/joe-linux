# There is no book page. Upstream's Makefile installs system-wide when
# DESTDIR is set: the extension under /usr/share/gnome-shell/extensions,
# its schema under /usr/share/glib-2.0/schemas (compiled by glib's
# trigger, and so open to joe-desktop's defaults) and its translations
# under /usr/share/locale. VERSION is given because there is no git
# repository to read it from.
package() {
    make VERSION="$PKG_VERSION" DESTDIR="$DESTDIR" install
    # The extension announces "Dash to Panel has been updated!" whenever the
    # version it last saw differs from its own, and a new account has seen
    # none. Starting from the packaged version keeps a new session quiet; an
    # upgrade is still announced once.
    cat > "$DESTDIR/usr/share/glib-2.0/schemas/10_dash-to-panel.gschema.override" <<EOT
[org.gnome.shell.extensions.dash-to-panel]
extension-version=$PKG_VERSION
EOT
}
