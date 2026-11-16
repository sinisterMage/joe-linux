# Not in the book: the newest upstream release, built as its README says.
# configure only picks Makefile.linux; the Makefile sets no optimization of
# its own.
build() {
    TARGET_OS=Linux ./configure
    make CFLAGS="-O2"
}

package() {
    make PREFIX=/usr DESTDIR="$DESTDIR" install
}
