# Not in the book: the newest upstream release, a C program built with its
# Makefile (the README only describes Flatpak builds; the Makefile's
# install target honours prefix and DESTDIR). Upstream publishes no
# checksum for the release archive.
build() {
    # VERSION_COMMIT comes from git, which a release archive is not: it is
    # left empty. CFLAGS are the Makefile's own (-O3 -flto).
    make prefix=/usr
}

package() {
    make prefix=/usr DESTDIR="$DESTDIR" install
}
