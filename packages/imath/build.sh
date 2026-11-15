build() {
    mkdir build
    cd build
    # The book's command, with PYTHON=OFF: the PyImath bindings need
    # Boost.Python and NumPy, and joe's Boost is built without Python.
    # Plus CMAKE_INSTALL_LIBDIR, so that nothing can pick lib64, and no
    # tests.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTING=OFF \
        -D PYTHON=OFF \
        -D PYBIND11=OFF \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
