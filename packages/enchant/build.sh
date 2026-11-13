# The book builds Enchant on Aspell. Here its one provider is Hunspell, which
# the page lists as optional: Hunspell dictionaries are the ones every
# desktop program and LibreOffice share. The other providers are switched
# off explicitly; none has a recipe.
#
# The provider looks for LANG.dic and LANG.aff in the "hunspell" directory
# of each XDG data directory, so in /usr/share/hunspell.
#
# nodist_doc_DATA is emptied because those are HTML copies of the manual
# pages made with groff, which does not exist here.
build() {
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --with-hunspell \
        --without-aspell \
        --without-nuspell \
        --without-hspell \
        --without-voikko \
        --without-zemberek
    make nodist_doc_DATA=
}

package() {
    make nodist_doc_DATA= DESTDIR="$DESTDIR" install
}
