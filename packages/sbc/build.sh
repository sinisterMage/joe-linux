# BLFS's SBC page. The tester needs libsndfile only to compare encodings.
build() {
    ./configure --prefix=/usr --disable-static --disable-tester
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
