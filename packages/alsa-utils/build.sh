# Following the book's alsa-utils page: no alsaconf (an old shell script for
# ISA cards), no alsabat (needs FFTW and is a test tool) and no xmlto
# manual pages (alsactl_init.7; xmlto has no recipe).
#
# alsactl's units (alsa-restore, alsa-state, alsa-card-wait@) and its udev
# rule are installed as the book installs them, and make install links
# alsa-restore and alsa-state into sound.target.wants: they are static
# units that udev pulls in when a sound card appears, and their conditions
# pick one of the two. The saved mixer state is /var/lib/alsa/asound.state.
build() {
    # FireWire audio through libffado is detected with no switch to turn it
    # off; it has no recipe, and upstream does not recommend it.
    ac_cv_lib_ffado_ffado_streaming_init=no \
    ./configure --prefix=/usr \
        --disable-alsaconf \
        --disable-bat \
        --disable-xmlto \
        --enable-rst2man \
        --with-curses=ncursesw \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-udev-rules-dir=/usr/lib/udev/rules.d
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # alsactl store writes /var/lib/alsa/asound.state but does not create
    # the directory, and /var is not packaged.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    echo 'd /var/lib/alsa 0755 root root -' > "$DESTDIR/usr/lib/tmpfiles.d/alsa-utils.conf"
}
