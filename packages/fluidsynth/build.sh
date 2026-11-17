# Not in the book: the newest upstream release, built as its README.cmake.md
# says.

prepare() {
    bsdtar -xf "$SOURCES/gcem-012ae73c6d0a2cb09ffe86475f5c6fba3926e200.zip" \
        --strip-components=1 -C gcem
    test -f gcem/include/gcem.hpp
}

build() {
    # On: ALSA (audio and sequencer MIDI), PulseAudio, PipeWire, file
    # output, libsndfile (SoundFont 3 and file rendering), D-Bus
    # (RealtimeKit), systemd, readline, network (server mode), threads,
    # OpenMP and native DLS loading.
    #
    # Off:
    # - signalsmith: the Signalsmith reverb and limiter need the
    #   signalsmith-audio-basics submodule and its own submodules, which
    #   have no recipe; the other reverb engines remain.
    # - LADSPA: needs the LADSPA SDK's ladspa.h, which has no recipe.
    # - PortAudio (off by default upstream; ALSA, PulseAudio and PipeWire
    #   already cover it), JACK, SDL3, MidiShare: no recipes or redundant.
    #   OSS is obsolete.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D enable-alsa=ON \
        -D enable-pulseaudio=ON \
        -D enable-pipewire=ON \
        -D enable-aufile=ON \
        -D enable-libsndfile=ON \
        -D enable-dbus=ON \
        -D enable-systemd=ON \
        -D enable-readline=ON \
        -D enable-network=ON \
        -D enable-ipv6=ON \
        -D enable-threads=ON \
        -D enable-openmp=ON \
        -D enable-native-dls=ON \
        -D enable-signalsmith=OFF \
        -D enable-ladspa=OFF \
        -D enable-portaudio=OFF \
        -D enable-jack=OFF \
        -D enable-sdl3=OFF \
        -D enable-midishare=OFF \
        -D enable-oss=OFF \
        -D enable-opensles=OFF \
        -D enable-oboe=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
