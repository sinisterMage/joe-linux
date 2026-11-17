# Following the book's QtKeychain page. The book installs into $QT6DIR;
# joe's Qt is in /usr, so is this, and the .pri file for qmake users goes
# beside Qt's own in /usr/lib/qt6/mkspecs.
build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_WITH_QT6=ON \
        -D BUILD_TESTING=OFF \
        -D BUILD_TRANSLATIONS=ON \
        -D LIBSECRET_SUPPORT=ON \
        -D ECM_MKSPECS_INSTALL_DIR=/usr/lib/qt6/mkspecs/modules \
        -W no-author ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
