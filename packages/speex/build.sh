# Following the book's Speex page, its speex part (speexdsp is its own
# recipe). The FFT is the built-in one (smallft); FFTW would be taken only
# with --with-fft=gpl-fftw3.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/speex-1.2.1
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
