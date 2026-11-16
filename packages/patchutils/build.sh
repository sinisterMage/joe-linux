# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    ./configure --prefix=/usr \
        --with-pcre2 \
        --with-diff=diff \
        --with-patch=patch \
        --disable-fuzzing
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
