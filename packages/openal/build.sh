# Not in the book: the newest upstream release, built with CMake as its
# README describes. Back ends: PipeWire, PulseAudio, ALSA and OSS, all
# loaded at run time, plus the WAVE file writer. Switched off because joe
# has no recipe for them: JACK, sndio. PortAudio and SDL are only
# alternative routes to the same sound servers, so they are off too.
#
# Programs: openal-info only. alsoft-config (a Qt 6 GUI) is not built; the
# configuration file is documented in usr/share/openal/alsoftrc.sample.
# makemhr and sofa-info need libmysofa, uhjdecoder and uhjencoder
# libsndfile; those are not built (CMAKE_DISABLE_FIND_PACKAGE), nor are the
# examples. C++20 modules (an upstream option that GCC 15+ enables) are off:
# the plain build is the one every distribution uses.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ALSOFT_ENABLE_MODULES=OFF \
        -D ALSOFT_EXAMPLES=OFF \
        -D ALSOFT_TESTS=OFF \
        -D ALSOFT_UTILS=ON \
        -D ALSOFT_NO_CONFIG_UTIL=ON \
        -D ALSOFT_UPDATE_BUILD_VERSION=OFF \
        -D CMAKE_DISABLE_FIND_PACKAGE_MySOFA=ON \
        -D CMAKE_DISABLE_FIND_PACKAGE_SndFile=ON \
        -D CMAKE_DISABLE_FIND_PACKAGE_SDL3=ON \
        -D ALSOFT_BACKEND_PIPEWIRE=ON \
        -D ALSOFT_BACKEND_PULSEAUDIO=ON \
        -D ALSOFT_BACKEND_ALSA=ON \
        -D ALSOFT_BACKEND_OSS=ON \
        -D ALSOFT_BACKEND_WAVE=ON \
        -D ALSOFT_BACKEND_JACK=OFF \
        -D ALSOFT_BACKEND_SNDIO=OFF \
        -D ALSOFT_BACKEND_PORTAUDIO=OFF \
        -D ALSOFT_BACKEND_SDL2=OFF \
        -D ALSOFT_BACKEND_SDL3=OFF \
        -D ALSOFT_RTKIT=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
