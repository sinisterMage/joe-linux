# Not in the book: the newest upstream release, built as its README says.
# opusdec plays directly through OSS when asked (the header is the
# kernel's); sndio is detected with no switch and has no recipe.
build() {
    ac_cv_lib_sndio_sio_open=no \
    ./configure --prefix=/usr \
        --with-flac
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
