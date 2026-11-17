# Not in the book: the newest upstream release, built with CMake as its
# INSTALL file describes for a Qt-only build. WITH_APPS="Qt;CLI" builds
# kid3-qt and kid3-cli; the KDE variant (kid3) would need KDE Frameworks,
# which joe does not package.
#
# - Ogg/Vorbis and FLAC through their own libraries, everything else through
#   TagLib. mp4v2 has no recipe; TagLib reads MP4 tags itself.
# - Chromaprint fingerprints are decoded with FFmpeg (chromaprint links it
#   anyway), named here so that GStreamer, which exists too, is not picked.
# - D-Bus (MPRIS) and QML scripting stay on, as upstream has them on Linux.
# - The libraries and plugins go in /usr/lib/kid3, upstream's default; the
#   programs find them through an rpath upstream sets.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_WITH_QT6=ON \
        -D BUILD_TESTING=OFF \
        -D WITH_APPS="Qt;CLI" \
        -D WITH_TAGLIB=ON \
        -D WITH_MP4V2=OFF \
        -D WITH_VORBIS=ON \
        -D WITH_FLAC=ON \
        -D WITH_CHROMAPRINT=ON \
        -D WITH_FFMPEG=ON \
        -D WITH_GSTREAMER=OFF \
        -D WITH_QAUDIODECODER=OFF \
        -D WITH_MULTIMEDIA=ON \
        -D WITH_DBUS=ON \
        -D WITH_QML=ON \
        -D WITH_READLINE=ON \
        -D WITH_DOC=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
