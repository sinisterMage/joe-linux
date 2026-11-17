# Not in the book: the newest upstream release, built with CMake as its
# README says.
#
# Switched off because joe has no recipe for what they need: audio CDs
# (libcdio) and iPod classic devices (libgpod). The test suite is not built
# (googletest is in the build root, so it is hidden from CMake). Global
# shortcuts through KGlobalAccel and passwords in KWallet are plain D-Bus
# clients and need no KDE library. Translations are compiled into the
# program, upstream's default. ccache, which is in the build root, is not
# used.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_DISABLE_FIND_PACKAGE_GTest=ON \
        -D CCACHE_EXECUTABLE=OFF \
        -D ENABLE_AUDIOCD=OFF \
        -D ENABLE_GPOD=OFF \
        -D ENABLE_MTP=ON \
        -D ENABLE_ALSA=ON \
        -D ENABLE_PULSE=ON \
        -D ENABLE_DBUS=ON \
        -D ENABLE_MPRIS2=ON \
        -D ENABLE_LIBSECRET=ON \
        -D ENABLE_CHROMAPRINT=ON \
        -D ENABLE_GSTFASTSPECTRUM=ON \
        -D ENABLE_EBUR128=ON \
        -D ENABLE_STREAMTAGREADER=ON \
        -D ENABLE_X11_GLOBALSHORTCUTS=ON \
        -D ENABLE_UDISKS2=ON \
        -D ENABLE_GIO=ON \
        -D ENABLE_GIO_UNIX=ON \
        -D ENABLE_TRANSLATIONS=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
