prepare() {
    # Remove a private definition of bool that conflicts with C23.
    sed -i '/typedef enum/,/bool ;/d' src/ALAC/alac_{en,de}coder.c
}

build() {
    # FLAC, Ogg, Vorbis and Opus are used (the book's recommended set).
    # MP3 needs LAME and mpg123, which do not exist here; ALSA would only
    # be used by sndfile-play and SQLite by a regression test tool.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-external-libs \
        --disable-mpeg \
        --disable-alsa \
        --disable-sqlite \
        --docdir=/usr/share/doc/libsndfile-1.2.2
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
