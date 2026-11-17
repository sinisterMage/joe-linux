# Not in the book: the newest upstream release, built as its README says.
build() {
    ./configure --prefix=/usr --disable-static --disable-werror
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # Upstream's English thesaurus (from WordNet 2.0), which it distributes
    # but does not install, under the name and in the directory where
    # applications look for a thesaurus (LibreOffice: th_en_US_v2 in
    # /usr/share/mythes).
    install -Dm644 th_en_US_new.dat "$DESTDIR/usr/share/mythes/th_en_US_v2.dat"
    install -Dm644 th_en_US_new.idx "$DESTDIR/usr/share/mythes/th_en_US_v2.idx"
}
