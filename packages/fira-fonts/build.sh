# Not in the book: upstream's last release (the repository is archived),
# whose ready-made OpenType files are installed as the book installs fonts:
# Fira Sans, Fira Sans Condensed, and Fira Mono (whose own version is
# 3.206). fontconfig's trigger rebuilds the cache.
package() {
    install -v -d -m755 "$DESTDIR/usr/share/fonts/fira"
    install -v -m644 otf/*.otf "$DESTDIR/usr/share/fonts/fira"
}
