# Not in the book (its fonts page only describes these fonts): upstream's
# latest release of the ready-made OpenType files, installed as the book
# installs fonts. fontconfig's trigger rebuilds the cache.
unpack() {
    bsdtar -xf "$SOURCES/$PKG_SOURCE" --no-same-owner --no-same-permissions
}

package() {
    install -v -d -m755 "$DESTDIR/usr/share/fonts/adobe-source-code-pro"
    install -v -m644 OTF/*.otf "$DESTDIR/usr/share/fonts/adobe-source-code-pro"
}
