# Not in the book: the newest upstream release, built as its INSTALL.adoc
# says. Wide-character ncurses, readline for the prompt and PCRE2 for
# searches are stated rather than detected. The release carries the manual
# pages already made, so AsciiDoc is not needed.
build() {
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --with-ncursesw \
        --with-readline=/usr \
        --with-pcre
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    install -Dm644 doc/tig.1 "$DESTDIR/usr/share/man/man1/tig.1"
    install -Dm644 doc/tigrc.5 "$DESTDIR/usr/share/man/man5/tigrc.5"
    install -Dm644 doc/tigmanual.7 "$DESTDIR/usr/share/man/man7/tigmanual.7"
    install -Dm644 contrib/tig-completion.bash \
        "$DESTDIR/usr/share/bash-completion/completions/tig"
}
