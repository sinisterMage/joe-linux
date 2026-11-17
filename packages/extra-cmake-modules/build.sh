# Following the book's Extra CMake Modules page.
prepare() {
    # The book's fixes: never choose lib64, and keep the package prefix
    # that ECMConfig.cmake computes when it includes other files.
    sed -i '/"lib64"/s/64//' kde-modules/KDEInstallDirsCommon.cmake
    sed -e '/PACKAGE_INIT/i set(SAVE_PACKAGE_PREFIX_DIR "${PACKAGE_PREFIX_DIR}")' \
        -e '/^include/a set(PACKAGE_PREFIX_DIR "${SAVE_PACKAGE_PREFIX_DIR}")' \
        -i ECMConfig.cmake.in
}

build() {
    mkdir build
    cd build
    # The manual pages are built with Sphinx; the HTML manual would only be
    # removed with the rest of /usr/share/doc, and the Qt Help one needs Qt
    # Assistant's qhelpgenerator, which joe's Qt does not build. The tests
    # are not run.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D BUILD_WITH_QT6=ON \
        -D DOC_INSTALL_DIR=/usr/share/doc/extra-cmake-modules-6.29.0 \
        -D BUILD_TESTING=OFF \
        -D BUILD_DOC=ON \
        -D BUILD_MAN_DOCS=ON \
        -D BUILD_HTML_DOCS=OFF \
        -D BUILD_QTHELP_DOCS=OFF \
        ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
