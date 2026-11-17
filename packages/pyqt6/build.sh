# Not in the book: the newest release on PyPI, configured with sip-build and
# compiled with make, the way upstream's documentation and other
# distributions build it.
#
# The bindings built are those for the Qt modules joe has: Core, Gui,
# Widgets, Network, D-Bus, QML and Quick (with Quick Controls 2 and Quick
# Widgets), OpenGL, Print Support, SQL, SVG, Test, XML, and from
# qt6-multimedia Multimedia, Multimedia Widgets and Spatial Audio. Help,
# Positioning, Serial Port, Web Channel, Web Sockets and Text to Speech
# are enabled now that their Qt modules are packaged. Designer, Quick 3D,
# Remote Objects, Sensors, Bluetooth, NFC, State Machine and the Windows-only
# QAxContainer remain off. Pdf moved to PyQt6-WebEngine with Qt 6.12.
#
# The Qt support for dbus-python (dbus.mainloop.pyqt6) is not built: it needs
# dbus-python's C header, which joe's dbus-python does not install. The
# qmlscene plugin, which lets QML load Python types, is built.
build() {
    sip-build \
        --confirm-license \
        --no-make \
        --build-dir build \
        --qmake /usr/lib/qt6/bin/qmake \
        --pep484-pyi \
        --no-dbus-python \
        --no-designer-plugin \
        --disable QtDesigner \
        --disable QtQuick3D \
        --disable QtRemoteObjects \
        --disable QtSensors \
        --disable QtBluetooth \
        --disable QtNfc \
        --disable QtPdf \
        --disable QtPdfWidgets \
        --disable QtStateMachine \
        --disable QAxContainer
    make -C build
}

package() {
    make -C build INSTALL_ROOT="$DESTDIR" install
    # The Python files installed by make (uic, lupdate, the stubs' package)
    # are compiled here: the installed tree is read-only.
    python3 -m compileall -q -d /usr/lib "$DESTDIR/usr/lib"
    python3 -O -m compileall -q -d /usr/lib "$DESTDIR/usr/lib"
}
