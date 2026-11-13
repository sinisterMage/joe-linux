# Not in the book, which checks spelling with Aspell; its Enchant page lists
# Hunspell as an optional provider. This is upstream's latest release, built
# as its README says. Dictionaries (hunspell-en) go in /usr/share/hunspell,
# the first directory the program searches and the one Enchant uses.
build() {
    # --with-ui and --with-readline give the hunspell program its
    # interactive mode; the library does not use them.
    ./configure --prefix=/usr \
        --disable-static \
        --with-ui \
        --with-readline
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
