# Not in the book: the newest upstream release (arpack-ng, the maintained
# continuation of ARPACK), built with CMake as its README says and
# configured as Arch Linux configures it, without MPI (PARPACK), which joe
# does not have. ICB adds the C and C++ interfaces (arpack.h, arpack.hpp)
# that Octave and SciPy-style users call; BLAS and LAPACK are separate libraries.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D BLA_VENDOR=Generic \
        -D ICB=ON \
        -D MPI=OFF \
        -D EIGEN=OFF \
        -D PYTHON3=OFF \
        -D EXAMPLES=OFF \
        -D TESTS=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
