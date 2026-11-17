# Not in the book: the newest upstream release, built as its README says.
build() {
    ./configure --prefix=/usr --disable-static
    make
}

package() {
    # The library, substrings.pl and the default dictionary,
    # /usr/share/hyphen/hyph_en_US.dic (made from the TeX patterns, and
    # shipped prebuilt in the tarball).
    make DESTDIR="$DESTDIR" install
}
