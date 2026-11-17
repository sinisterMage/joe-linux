# Not in the book: newest upstream stable, following its CMake instructions.
# Build CLI + Qt GUI, USB, compressed files and all formats. The GUI's map
# preview needs Qt WebEngine, which joe does not package yet, so it is off.
# Upstream has no Unix install target: stage the actual binaries and desktop resources.
prepare() {
    sed -i 's|QApplication::applicationDirPath() + "/translations"|QStringLiteral("/usr/share/gpsbabel/translations")|' gui/mainwindow.cc
}

build() {
    cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -DGPSBABEL_WITH_ZLIB=pkgconfig -DGPSBABEL_WITH_LIBUSB=pkgconfig \
        -DGPSBABEL_WITH_SHAPELIB=included -DGPSBABEL_MAPPREVIEW=OFF \
        -DGPSBABEL_ENABLE_PCH=ON
    cmake --build build -j"$JOBS"
    mkdir -p build/translations
    local ts
    for ts in gui/gpsbabelfe_*.ts gui/coretool/gpsbabel_*.ts; do
        /usr/lib/qt6/bin/lrelease "$ts" -qm "build/translations/$(basename "${ts%.ts}").qm"
    done
}

package() {
    install -Dm755 build/gpsbabel "$DESTDIR/usr/bin/gpsbabel"
    install -Dm755 build/gui/GPSBabelFE/gpsbabelfe "$DESTDIR/usr/bin/gpsbabelfe"
    install -Dm644 gui/gpsbabel.desktop "$DESTDIR/usr/share/applications/gpsbabel.desktop"
    install -Dm644 gui/images/appicon.png "$DESTDIR/usr/share/icons/hicolor/64x64/apps/gpsbabel.png"
    install -d "$DESTDIR/usr/share/gpsbabel/translations"
    install -m644 build/translations/*.qm "$DESTDIR/usr/share/gpsbabel/translations/"
}
