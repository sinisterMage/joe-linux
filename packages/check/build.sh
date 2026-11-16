# Not in the book: the newest upstream release (from 2020), built as its
# README says. The subunit protocol is off (libsubunit has no recipe), and
# the Texinfo manual is not built: the Info manuals are not shipped.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-subunit \
        --disable-build-docs \
        --disable-gcov
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
