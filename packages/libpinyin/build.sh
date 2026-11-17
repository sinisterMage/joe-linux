# Not in the book: the newest stable upstream release, built as its
# INSTALL says.
build() {
    # libzhuyin (the Zhuyin library built from the same source) is only
    # used by ibus-libzhuyin, which has no recipe.
    ./configure --prefix=/usr \
        --disable-static \
        --with-dbm=KyotoCabinet \
        --disable-libzhuyin
    # The build runs the programs it has just built to turn the language
    # model into the binary databases installed in /usr/lib/libpinyin/data.
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
