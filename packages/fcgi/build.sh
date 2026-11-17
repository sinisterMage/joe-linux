# Not in the book: the newest upstream release, built as its README says.
# The tag's archive carries no configure script, so autogen.sh makes it.
prepare() {
    ./autogen.sh
}

build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-examples
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
