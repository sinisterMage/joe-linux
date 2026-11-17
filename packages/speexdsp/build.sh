# Following the book's Speex page, its speexdsp part (the Speex codec itself
# is not packaged). The FFT is the built-in one (smallft); FFTW would be
# taken only with --with-fft=gpl-fftw3.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-examples \
        --docdir=/usr/share/doc/speexdsp-1.2.1
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
