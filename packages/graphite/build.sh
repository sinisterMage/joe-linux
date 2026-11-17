# Following the book's graphite2 page. The book's version (upstream has
# since released 1.3.15).
prepare() {
    # The test programs are built with the library; these tests need
    # FontTools.
    sed -i '/cmptest/d' tests/CMakeLists.txt
    # CMake 4.
    sed -i '/cmake_policy(SET CMP0012 NEW)/d' CMakeLists.txt
    sed -i 's/PythonInterp/Python3/' CMakeLists.txt
    find . -name CMakeLists.txt | xargs sed -i 's/VERSION 2.8.0 FATAL_ERROR/VERSION 4.0.0/'
    # GCC 15 and later.
    sed -i '/Font.h/i #include <cstdint>' tests/featuremap/featuremaptest.cpp
}

build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        ..
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install
}
