# Not in the book: the newest upstream release, built as its README says.
# The manual pages are made from the POD sources with Perl's pod2man.
build() {
    ./configure --prefix=/usr
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
