# Not in the book: the newest upstream release, built as its INSTALL
# says, with the conversion tools, without documentation or -Werror.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-werror \
        --without-docs \
        --enable-tools
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
