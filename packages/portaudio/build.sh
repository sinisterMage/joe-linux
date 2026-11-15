# Not in the book: the newest upstream release (19.7.0), built with its
# configure script as README.configure.txt says.
build() {
    # ALSA is the one host API: sound servers (PipeWire, PulseAudio) are
    # reached through their ALSA plugins. 19.7.0 has no PulseAudio or
    # PipeWire host API of its own; JACK has no recipe; OSS devices do not
    # exist here. No C++ binding (libportaudiocpp): nothing uses it.
    ./configure --prefix=/usr \
        --disable-static \
        --with-alsa \
        --without-jack \
        --without-oss \
        --without-asihpi \
        --disable-cxx
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
