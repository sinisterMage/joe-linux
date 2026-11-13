# The book's fonts page installs TTF files by hand; the tarball's meson.build
# does nothing more than copy the same six files to the same directory.
package() {
    install -v -d -m755 "$DESTDIR/usr/share/fonts/Adwaita"
    install -v -m644 mono/*.ttf sans/*.ttf "$DESTDIR/usr/share/fonts/Adwaita"
}
