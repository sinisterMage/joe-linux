# Not in the book: the newest database release, installed with
# osinfo-db-import as upstream's README says. The archive is the built
# database (not the osinfo-db-dist sources), so nothing is compiled.
unpack() {
    # osinfo-db-import reads the archive itself.
    :
}

package() {
    osinfo-db-import --root "$DESTDIR" --dir /usr/share/osinfo "$SOURCES/$PKG_SOURCE"
}
