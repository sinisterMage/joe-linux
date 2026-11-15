# Not in the book: the newest upstream release, installed with CMake as its
# INSTALL file describes. Upstream publishes no checksum for the archive.
build() {
    mkdir build
    cd build
    # Only the headers (Eigen and unsupported/Eigen) and the CMake and
    # pkg-config files are installed. Eigen's own BLAS and LAPACK
    # libraries, the demos, the tests and the Doxygen documentation are
    # off.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTING=OFF \
        -D EIGEN_BUILD_TESTING=OFF \
        -D EIGEN_BUILD_BLAS=OFF \
        -D EIGEN_BUILD_LAPACK=OFF \
        -D EIGEN_BUILD_DOC=OFF \
        -D EIGEN_BUILD_DEMOS=OFF \
        -D EIGEN_BUILD_PKGCONFIG=ON \
        -D EIGEN_BUILD_CMAKE_PACKAGE=ON \
        -G Ninja ..
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
