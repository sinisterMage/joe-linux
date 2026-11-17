# Not in the book: the newest upstream release, built with its configure
# script, with the conversion tools, without unit tests (they need cppunit),
# documentation or -Werror.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-werror \
        --disable-tests \
        --without-docs \
        --enable-tools
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
