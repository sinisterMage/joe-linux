# Not in the book: upstream's latest release of the ready-made fonts,
# installed as its help.txt says: both the static family (Inter.ttc, with
# Inter Display) and the variable one, which is named "Inter Variable" so
# that the two can be installed side by side. fontconfig's trigger
# rebuilds the cache.
unpack() {
    # The zip file has no top-level directory.
    bsdtar -xf "$SOURCES/$PKG_SOURCE" --no-same-owner --no-same-permissions
}

package() {
    install -v -d -m755 "$DESTDIR/usr/share/fonts/inter"
    install -v -m644 Inter.ttc InterVariable.ttf InterVariable-Italic.ttf "$DESTDIR/usr/share/fonts/inter"
}
