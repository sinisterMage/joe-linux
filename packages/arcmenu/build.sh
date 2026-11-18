# There is no book page. Upstream's Makefile installs system-wide when
# DESTDIR is set, with the schema under /usr/share/glib-2.0/schemas (for
# glib's trigger, and joe-desktop's defaults). VERSION is given because
# there is no git repository to read it from.
package() {
    make VERSION="$PKG_VERSION" DESTDIR="$DESTDIR" install
}
