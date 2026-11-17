# Not in the book: the newest upstream release, built with CMake as
# upstream's Linux build instructions (and Arch Linux's package) do.
#
# Built: the Qt 6 interface, capture of PipeWire (Wayland screens and
# windows through the desktop portal), X11 screens and windows, V4L2
# cameras, ALSA and PulseAudio; encoding through FFmpeg and VA-API, x264,
# and the RTMP(S) (Mbed TLS), SRT and RIST outputs; the obs-websocket
# remote-control server; Lua and Python scripting; the SpeexDSP and RNNoise
# noise filters (RNNoise is the copy OBS carries: joe has no rnnoise
# recipe, and the switch below keeps a later one from being picked up
# silently); VST 2 plugins (OBS's own reimplemented header); the VLC video
# source, which dlopen()s libvlc when a source uses it, so it works once the
# vlc package is installed.
#
# Switched off:
# - the browser source and browser docks (CEF, the Chromium Embedded
#   Framework, which joe does not package), and with them the "What's New"
#   dialog and the Twitch, YouTube and Restream integrations (which also need
#   client keys that only upstream's builds carry);
# - hardware that needs vendor SDKs or proprietary drivers: NVIDIA NVENC,
#   AJA, Blackmagic DeckLink, Intel QSV (oneVPL and its GPU runtime have no
#   recipes; FFmpeg's VA-API encoders remain, wherever the GPU has a VA-API
#   driver);
# - WebRTC (WHIP) output: libdatachannel and its libjuice, libsrtp and
#   usrsctp chain have no recipes;
# - JACK (joe's PipeWire is built without its JACK library), sndio, and the
#   FDK AAC encoder (FFmpeg's AAC encoder is used).
#
# Warnings are not errors: upstream's default would fail on whatever a
# newer GCC warns about. Mesa is built without libglvnd, so CMake finds
# OpenGL as libGL.so (LEGACY) rather than libOpenGL.so.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_COMPILE_WARNING_AS_ERROR=OFF \
        -D OpenGL_GL_PREFERENCE=LEGACY \
        -D OBS_VERSION_OVERRIDE="$PKG_VERSION" \
        -D ENABLE_FRONTEND=ON \
        -D ENABLE_WAYLAND=ON \
        -D ENABLE_PULSEAUDIO=ON \
        -D ENABLE_PIPEWIRE=ON \
        -D ENABLE_ALSA=ON \
        -D ENABLE_V4L2=ON \
        -D ENABLE_UDEV=ON \
        -D ENABLE_HEVC=ON \
        -D ENABLE_NEW_MPEGTS_OUTPUT=ON \
        -D ENABLE_WEBSOCKET=ON \
        -D ENABLE_SCRIPTING=ON \
        -D ENABLE_SCRIPTING_LUA=ON \
        -D ENABLE_SCRIPTING_PYTHON=ON \
        -D ENABLE_SPEEXDSP=ON \
        -D ENABLE_RNNOISE=ON \
        -D CMAKE_DISABLE_FIND_PACKAGE_Librnnoise=ON \
        -D ENABLE_FREETYPE=ON \
        -D ENABLE_VST=ON \
        -D ENABLE_VLC=ON \
        -D ENABLE_BROWSER=OFF \
        -D ENABLE_WHATSNEW=OFF \
        -D ENABLE_WEBRTC=OFF \
        -D ENABLE_NVENC=OFF \
        -D ENABLE_FFMPEG_NVENC=OFF \
        -D ENABLE_QSV11=OFF \
        -D ENABLE_AJA=OFF \
        -D ENABLE_DECKLINK=OFF \
        -D ENABLE_JACK=OFF \
        -D ENABLE_SNDIO=OFF \
        -D ENABLE_LIBFDK=OFF \
        -D ENABLE_TEST_INPUT=OFF \
        -D ENABLE_RELOCATABLE=OFF \
        -D ENABLE_PORTABLE_CONFIG=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
