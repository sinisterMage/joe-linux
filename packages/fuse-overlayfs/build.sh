# Not in the book: the newest upstream release, built as its README says.
# The archive is a plain export of the tag, so the build system is
# generated first (autogen.sh). The manual page is pregenerated.
prepare() {
    autoreconf -fis
}

build() {
    ./configure --prefix=/usr
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
