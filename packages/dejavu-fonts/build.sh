package() {
    install -v -d -m755 "$DESTDIR/usr/share/fonts/dejavu"
    install -v -m644 ttf/*.ttf "$DESTDIR/usr/share/fonts/dejavu"
}
