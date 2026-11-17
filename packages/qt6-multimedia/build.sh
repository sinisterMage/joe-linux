# Not in the book as a module of its own: the book's Qt6 page builds
# qtmultimedia inside qt-everywhere. This builds the same release from the
# module's own tarball against the installed qt6, as other distributions do;
# Qt's build internals (installed by qt6) put everything where qt6 put its
# own modules (/usr/lib/qt6/plugins, /usr/lib/qt6/qml, /usr/include/qt6).
#
# The backend is FFmpeg, Qt's default on Linux, with PulseAudio and PipeWire
# for sound, VA-API for hardware decoding, Video4Linux cameras and PipeWire
# screen capture. The GStreamer backend, an alternative to FFmpeg, is not
# built, nor the experimental ALSA output. Spatial audio for Qt Quick 3D
# needs Qt Quick 3D, which joe does not have.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D QT_BUILD_EXAMPLES=OFF \
        -D QT_BUILD_TESTS=OFF \
        -D QT_GENERATE_SBOM=OFF \
        -D FEATURE_ffmpeg=ON \
        -D FEATURE_gstreamer=OFF \
        -D FEATURE_pulseaudio=ON \
        -D FEATURE_alsa=OFF \
        -D FEATURE_pipewire=ON \
        -D FEATURE_vaapi=ON \
        -D FEATURE_linux_v4l=ON \
        -D FEATURE_spatialaudio=ON \
        -D FEATURE_spatialaudio_quick3d=OFF
    ninja -C build -j"$JOBS"
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
    # As in qt6: the build directory recorded in .prl files.
    find "$DESTDIR/usr" -name '*.prl' -exec sed -i -e '/^QMAKE_PRL_BUILD_DIR/d' {} \;
}
