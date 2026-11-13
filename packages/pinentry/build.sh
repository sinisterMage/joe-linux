build() {
    # Three front ends: tty, curses and GNOME 3 (the Gcr 4 system prompt that
    # GNOME Shell draws). /usr/bin/pinentry points at pinentry-gnome3, which
    # falls back to curses when there is no session bus to ask, so the one
    # default serves the desktop, a console and an ssh login alike.
    # libsecret lets the curses and tty front ends offer to save a passphrase
    # in the keyring. No Qt, GTK 2, FLTK, EFL or Emacs in joe.
    ./configure --prefix=/usr \
        --enable-pinentry-tty \
        --enable-pinentry-curses \
        --enable-fallback-curses \
        --enable-pinentry-gnome3 \
        --enable-libsecret \
        --disable-pinentry-emacs \
        --disable-inside-emacs \
        --disable-pinentry-gtk2 \
        --disable-pinentry-qt \
        --disable-pinentry-qt5 \
        --disable-pinentry-qt4 \
        --disable-pinentry-tqt \
        --disable-pinentry-fltk \
        --disable-pinentry-efl
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
