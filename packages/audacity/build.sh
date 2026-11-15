# Not in the book: the newest upstream release, Audacity 4.0.2, built from
# its release source snapshot as OFFLINE_BUILD.md and BUILDING.md say.
# Audacity 4 is a Qt Quick application on MuseScore's framework; it uses
# only the base (non-GUI) library of wxWidgets.

unpack() {
    # The snapshot was made on macOS: leave out its AppleDouble "._*"
    # files, which would otherwise sit next to the real sources.
    tar -xf "$SOURCES/audacity-sources-4.0.2.tar.xz" --strip-components=1 \
        --no-same-owner --no-same-permissions \
        --warning=no-unknown-keyword --exclude='._*'
}

prepare() {
    # Qt's own translations are copied from ${QT_INSTALL_PREFIX}/translations,
    # which is /usr/translations here and does not exist (Qt's data is under
    # /usr/share/qt6, and its translations are not built). Installing a
    # missing directory fails, so drop that step.
    grep -q 'install(DIRECTORY ${QT_INSTALL_PREFIX}/translations/' share/locale/CMakeLists.txt
    sed -i '/install(DIRECTORY ${QT_INSTALL_PREFIX}\/translations\//,/EXCLUDE)$/d' \
        share/locale/CMakeLists.txt

    # The desktop file is named "Audacity 4 Portable" whatever is built;
    # this is an installed build, not the AppImage.
    grep -q 'set(DESKTOP_LAUNCHER_NAME "${MUSE_APP_NAME_VERSION} Portable")' \
        buildscripts/packaging/Linux+BSD/SetupAppImagePackaging.cmake
    sed -i 's/set(DESKTOP_LAUNCHER_NAME "${MUSE_APP_NAME_VERSION} Portable")/set(DESKTOP_LAUNCHER_NAME "${MUSE_APP_TITLE}")/' \
        buildscripts/packaging/Linux+BSD/SetupAppImagePackaging.cmake
}

build() {
    local src=$PWD
    mkdir build
    cd build
    # Dependencies (muse_deps): every library comes from the system
    # (EXTDEPS_OVERRIDE_ALL=SYSTEM), so nothing is downloaded or built from
    # muse_deps. Code that the build compiles in comes from the archives in
    # offline-deps/ (EXTDEPS_CACHE), verified against their pinned hashes:
    # Nyquist, PFFFT, the tempo estimator, picojson and tft, which have no
    # system form, and these five, which would otherwise be looked for on
    # the system and have no recipe: the LV2 host libraries (lilv, serd,
    # sord, sratom, suil, zix), the VST3 SDK, RapidJSON, pugixml and utfcpp,
    # and SBSMS (the time stretching of the Sliding Stretch effect, which is
    # compiled whether or not SBSMS is enabled).
    # libid3tag's library is named id3tag; muse_deps looks for "libid3tag".
    #
    # Switched off: crash reporting (crashpad), update checks, audio.com
    # sign-in and upload, the usage statistics sent to audio.com, ccache
    # and the unit tests. The release
    # mode leaves out the test-flow scripts and marks the build stable.
    # The VST3 host stays on: the framework always builds its VST module.
    # QT_QML_NO_CACHEGEN: the C++ that Qt 6.12's qmlcachegen generates
    # ahead of time for Audacity's QML does not compile ("reference to
    # 'Type' is ambiguous"), so the QML is compiled when it is loaded.
    # env -u DESTDIR: the build environment exports DESTDIR, and the
    # dependency manager installs what it builds (SBSMS) into the build
    # directory while configuring; DESTDIR would send it elsewhere.
    env -u DESTDIR cmake -D CMAKE_BUILD_TYPE=Release \
        -D QT_QML_NO_CACHEGEN=ON \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D AU4_BUILD_CONFIGURATION=app \
        -D AU4_BUILD_MODE=release \
        -D EXTDEPS_CACHE="$src/offline-deps" \
        -D EXTDEPS_OVERRIDE_ALL=SYSTEM \
        -D EXTDEPS_OVERRIDE_LV2SDK=REBUILD \
        -D EXTDEPS_OVERRIDE_VST3SDK=REBUILD \
        -D EXTDEPS_OVERRIDE_RAPIDJSON=REBUILD \
        -D EXTDEPS_OVERRIDE_PUGIXML=REBUILD \
        -D EXTDEPS_OVERRIDE_UTFCPP=REBUILD \
        -D libid3tag_LIB_libid3tag=/usr/lib/libid3tag.so \
        -D MUSE_ENABLE_UNIT_TESTS=OFF \
        -D MUSE_MODULE_DIAGNOSTICS_CRASHPAD_CLIENT=OFF \
        -D MUSE_MODULE_UPDATE=OFF \
        -D MUSE_COMPILE_USE_CCACHE=OFF \
        -D AU_BUILD_CLOUD_AUDIOCOM=OFF \
        -D AU_BUILD_USAGEINFO_MODULE=OFF \
        -D AU_USE_SBSMS=ON \
        -D EXTDEPS_OVERRIDE_SBSMS=REBUILD \
        -D AU_USE_SOUNDTOUCH=ON \
        -D AU_MODULE_EFFECTS_LV2=ON \
        -D AU_MODULE_EFFECTS_VST=ON \
        -D AU_MODULE_EFFECTS_NYQUIST=ON \
        -D AU_RUN_LRELEASE=ON \
        -G Ninja ..
    env -u DESTDIR ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
