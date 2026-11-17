# Not in the book: the newest upstream release, built with CMake as its
# readme/LinuxBuild.md says.
build() {
    # Every optional feature stated:
    # - audio recording and playback off: it needs PortAudio's C++
    #   binding (portaudiocpp), and joe's portaudio is built without it;
    # - cpptrace off (upstream turns it off for Release builds anyway; it
    #   would be fetched at configure time);
    # - qpdf export, Lua plugins, GtkSourceView and X11 (XInput) on;
    # - the manual pages are made uncompressed.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_AUDIO=OFF \
        -D ENABLE_CPPTRACE=OFF \
        -D ENABLE_QPDF=ON \
        -D ENABLE_PLUGINS=ON \
        -D ENABLE_GTK_SOURCEVIEW=ON \
        -D CMAKE_REQUIRED_FIND_PACKAGE_X11=ON \
        -D ENABLE_PROFILING=OFF \
        -D ENABLE_GTEST=OFF \
        -D WITH_MAN=ON \
        -D MAN_COMPRESS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
