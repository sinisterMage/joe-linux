# Following the book's Qt6 page, with two differences:
# - Qt is installed in /usr, as everything else is, laid out as other
#   distributions lay it out: the libraries in /usr/lib, Qt's own programs
#   and data under /usr/lib/qt6 and /usr/share/qt6, the headers under
#   /usr/include/qt6. CMake finds it through /usr/lib/cmake/Qt6.
# - Only the modules joe's programs use are built (-submodules builds those
#   and what they need): Qt Quick, its controls and shader tools (the
#   installer, installer/), Qt Wayland (applications in a GNOME session),
#   Qt SVG (icons), from Qt Tools only the Linguist programs (lrelease,
#   lupdate) that applications such as KeePassXC translate themselves with,
#   and Qt 5 Compat and Qt Network Authorization, which Audacity uses.
#   The book removes the modules it cannot build instead.
#
# What the book leaves out by default stays out: examples, tests, an rpath,
# the SBOM. Printing goes through CUPS, and double-conversion is the
# system's. Of the SQL drivers only SQLite's is built: PostgreSQL's would
# make every Qt installation carry the database server's package, and
# MySQL and ODBC have no recipes. OpenSSL, D-Bus and the system's SQLite
# are linked as the book links them; messages go to the journal.
build() {
    mkdir build
    cd build
    ../configure -prefix /usr \
        -release \
        -sysconfdir /etc/xdg \
        -dbus-linked \
        -openssl-linked \
        -system-sqlite \
        -nomake examples \
        -nomake tests \
        -no-rpath \
        -no-sbom \
        -journald \
        -submodules qtdeclarative,qtwayland,qtsvg,qttools,qt5compat,qtnetworkauth \
        -- \
        -D FEATURE_system_doubleconversion=ON \
        -D FEATURE_cups=ON \
        -D FEATURE_sql_psql=OFF \
        -D FEATURE_sql_mysql=OFF \
        -D FEATURE_sql_odbc=OFF \
        -D FEATURE_assistant=OFF \
        -D FEATURE_designer=OFF \
        -D FEATURE_qdoc=OFF \
        -D FEATURE_clang=OFF \
        -D FEATURE_distancefieldgenerator=OFF \
        -D FEATURE_pixeltool=OFF \
        -D INSTALL_BINDIR=lib/qt6/bin \
        -D INSTALL_LIBEXECDIR=lib/qt6 \
        -D INSTALL_ARCHDATADIR=lib/qt6 \
        -D INSTALL_PLUGINSDIR=lib/qt6/plugins \
        -D INSTALL_QMLDIR=lib/qt6/qml \
        -D INSTALL_MKSPECSDIR=lib/qt6/mkspecs \
        -D INSTALL_DATADIR=share/qt6 \
        -D INSTALL_INCLUDEDIR=include/qt6 \
        -D INSTALL_DOCDIR=share/doc/qt6 \
        -D INSTALL_EXAMPLESDIR=share/doc/qt6/examples
    ninja -j"$JOBS"
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # The book's clean-up of the build directory recorded in .prl files.
    find "$DESTDIR/usr" -name '*.prl' -exec sed -i -e '/^QMAKE_PRL_BUILD_DIR/d' {} \;
    # The tools people run by hand, under their usual names.
    install -d "$DESTDIR/usr/bin"
    local tool
    for tool in qmake qtpaths; do
        [[ -e $DESTDIR/usr/lib/qt6/bin/$tool ]] && ln -s ../lib/qt6/bin/$tool "$DESTDIR/usr/bin/${tool}6"
    done
    return 0
}
