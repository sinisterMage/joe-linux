# The book has no Hunspell dictionaries. These are the SCOWL ones, the same
# release (2026.02.25) of the same word lists as the Aspell dictionary on the
# book's Aspell page.
#
# British English comes in three forms: -ise, -ize (Oxford) and "large",
# which accepts both but is less carefully checked. The -ise one, the
# spelling most British writers use, is installed as en_GB.
#
# /usr/share/hunspell is where both the hunspell program and Enchant's
# Hunspell provider look. The book makes no /usr/share/myspell link, and
# nothing here needs one.
unpack() {
    bsdtar -xf "$SOURCES/hunspell-en_US-2026.02.25.zip" --no-same-owner --no-same-permissions
    bsdtar -xf "$SOURCES/hunspell-en_GB-ise-2026.02.25.zip" --no-same-owner --no-same-permissions
}

package() {
    install -v -d -m755 "$DESTDIR/usr/share/hunspell"
    install -v -m644 en_US.aff en_US.dic "$DESTDIR/usr/share/hunspell"
    install -v -m644 en_GB-ise.aff "$DESTDIR/usr/share/hunspell/en_GB.aff"
    install -v -m644 en_GB-ise.dic "$DESTDIR/usr/share/hunspell/en_GB.dic"
}
