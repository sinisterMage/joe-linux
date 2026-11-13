build() {
    # The book runs a bare configure, which builds an output module for
    # every sound library it finds. Named here instead: ALSA (the default,
    # routed to pipewire by alsa-lib's configuration) and PulseAudio; SDL,
    # JACK, OpenAL and PortAudio have no recipes. Plain HTTP streams
    # are read by mpg123 itself; for HTTPS it runs curl.
    ./configure --prefix=/usr \
        --disable-static \
        --with-audio=alsa,pulse \
        --with-default-audio=alsa,pulse \
        --with-network=exec
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
