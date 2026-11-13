build() {
    # The book's --enable-vcut, plus:
    # - ogg123, the player, needs libao, which does not exist here (libcurl
    #   is only used by it).
    # - Speex and libkate do not exist here.
    ./configure --prefix=/usr \
        --enable-vcut \
        --disable-ogg123 \
        --with-flac \
        --without-speex \
        --without-kate
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
