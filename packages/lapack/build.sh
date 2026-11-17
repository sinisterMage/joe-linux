# Not in the book: Reference LAPACK stable release, using external OpenBLAS.
# LP64 (32-bit Fortran integers), gfortran ABI; OpenBLAS owns BLAS/CBLAS only.
build() {
    cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF \
        -DUSE_OPTIMIZED_BLAS=ON -DBLAS_LIBRARIES=/usr/lib/libopenblas.so \
        -DUSE_OPTIMIZED_LAPACK=OFF -DCBLAS=OFF -DLAPACKE=ON \
        -DBUILD_INDEX64=OFF -DBUILD_INDEX64_EXT_API=OFF \
        -DBUILD_DEPRECATED=ON -DLAPACKE_WITH_TMG=OFF \
        -DBUILD_HTML_DOCUMENTATION=OFF -DBUILD_MAN_DOCUMENTATION=OFF
    cmake --build build -j"$JOBS"
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
