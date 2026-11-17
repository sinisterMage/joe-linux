# Following the book's libsamplerate page.
build() {
    # libsndfile, ALSA and FFTW are used only by the example programs (which
    # are not installed) and the tests; without them neither is built, and
    # the library is the same.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-sndfile \
        --disable-alsa \
        --disable-fftw \
        --docdir=/usr/share/doc/libsamplerate-0.2.2
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
