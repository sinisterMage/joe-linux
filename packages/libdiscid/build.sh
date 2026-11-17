# Not in the book: the newest upstream release, built with autotools as its
# INSTALL file says. The URLs it composes for MusicBrainz use HTTPS.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --enable-use-https
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
