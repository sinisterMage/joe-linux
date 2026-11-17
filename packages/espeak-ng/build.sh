# Not in the book: the newest upstream release, built with autotools as
# docs/building.md describes. The CMake build is not used because it clones
# libsonic from GitHub when the library is missing.
prepare() {
    # Upstream's clause-terminator API keeps Calibre's TTS punctuation intact.
    patch -Np1 -i "$SOURCES/espeak-ng-phoneme-terminator.patch"
    # What autogen.sh does, without its search for libtoolize with which.
    mkdir -p m4
    touch AUTHORS
    ln -sf ChangeLog.md NEWS
    ln -sf README.md README
    autoreconf -fi
}

build() {
    # - pcaudiolib and sonic have no recipe: espeak-ng itself writes audio
    #   to files or standard output only (-w, --stdout); Speech Dispatcher,
    #   its main user here, plays the samples it gets back itself.
    # - mbrola: the voices run the mbrola program, which has no recipe.
    # - Klatt and speechPlayer are built in and need nothing.
    # - The manual pages are written in ronn, which joe does not have; the
    #   cache variable keeps one that appears in the build root from being
    #   used.
    # The static library is built (speak-ng links it with -static) and
    # removed in package().
    ac_cv_prog_RONN=no \
    ./configure --prefix=/usr \
        --disable-rpath \
        --with-pcaudiolib=no \
        --with-sonic=no \
        --with-mbrola=no \
        --with-klatt=yes \
        --with-speechplayer=yes \
        --with-async=yes
    # docs/building.md: the voice data cannot be built with -jN. The
    # programs can; the phoneme tables and dictionaries are then compiled
    # one at a time by the espeak-ng just built.
    make src/espeak-ng src/speak-ng
    make -j1
}

package() {
    make -j1 DESTDIR="$DESTDIR" install
    rm -f "$DESTDIR"/usr/lib/libespeak-ng.a
}
