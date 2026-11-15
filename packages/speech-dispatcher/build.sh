# Not in the book: the newest upstream release, built as INSTALL describes.
build() {
    # Output modules: espeak-ng only. espeak (the old one), Flite, Pico,
    # IVONA and the proprietary engines (IBM TTS, Voxin, Baratinoo, Kali,
    # which would otherwise be built as shims that dlopen the vendor's
    # library) have no recipe. The generic, festival, cicero, openjtalk and
    # dummy modules need nothing at build time and are always built.
    # Audio: PulseAudio, PipeWire and ALSA; libao, OSS and NAS have no
    # recipe. pulse is also what upstream picks first when it is found.
    # --disable-ltdl: modules are opened with dlopen, not libtool's libltdl.
    # The systemd units are installed but not enabled; clients start the
    # server themselves when nothing is listening.
    # The Texinfo manuals are not shipped, and the manual page of the
    # server would be made with help2man; the cache variable keeps one that
    # appears in the build root from being used.
    ac_cv_prog_HELP2MAN= \
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --disable-doc \
        --disable-ltdl \
        --enable-python \
        --with-espeak-ng \
        --without-espeak \
        --without-flite \
        --without-ibmtts \
        --without-voxin \
        --without-ivona \
        --without-pico \
        --without-baratinoo \
        --without-kali \
        --with-pulse \
        --with-pipewire \
        --with-alsa \
        --without-libao \
        --without-oss \
        --without-nas \
        --with-default-audio-method=pulse \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-systemduserunitdir=/usr/lib/systemd/user \
        PYTHON=/usr/bin/python3
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
