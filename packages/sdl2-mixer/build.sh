# Not in the book: the newest SDL 2 release of SDL_mixer, built with its
# CMake build, configured as distributions configure it: the system
# libraries for every format, linked directly (SDL2MIXER_DEPS_SHARED=OFF),
# none of the copies in external/ (SDL2MIXER_VENDORED=OFF), and libFLAC,
# mpg123 and libvorbisfile rather than the single-file decoders (dr_flac,
# minimp3, stb_vorbis). MIDI: FluidSynth, and the built-in Timidity for
# GUS patches. Switched off because joe has no recipe for it:
# game-music-emu (GME); MOD files go through libxmp, not libmodplug.
# The sample programs (playmus, playwave) are not built.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D SDL2MIXER_VENDORED=OFF \
        -D SDL2MIXER_DEPS_SHARED=OFF \
        -D SDL2MIXER_SAMPLES=OFF \
        -D SDL2MIXER_CMD=ON \
        -D SDL2MIXER_FLAC=ON \
        -D SDL2MIXER_FLAC_LIBFLAC=ON \
        -D SDL2MIXER_FLAC_DRFLAC=OFF \
        -D SDL2MIXER_GME=OFF \
        -D SDL2MIXER_MOD=ON \
        -D SDL2MIXER_MOD_MODPLUG=OFF \
        -D SDL2MIXER_MOD_XMP=ON \
        -D SDL2MIXER_MOD_XMP_LITE=OFF \
        -D SDL2MIXER_MP3=ON \
        -D SDL2MIXER_MP3_MINIMP3=OFF \
        -D SDL2MIXER_MP3_MPG123=ON \
        -D SDL2MIXER_MIDI=ON \
        -D SDL2MIXER_MIDI_FLUIDSYNTH=ON \
        -D SDL2MIXER_MIDI_TIMIDITY=ON \
        -D SDL2MIXER_OPUS=ON \
        -D SDL2MIXER_VORBIS=VORBISFILE \
        -D SDL2MIXER_WAVE=ON \
        -D SDL2MIXER_WAVPACK=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
