# Not in the book: the newest upstream release, built with its Makefile as
# its README says.
#
# OpenBLAS supplies optimized BLAS and CBLAS. Reference LAPACK and LAPACKE
# are packaged separately so their standard library names have one owner.
#
# Threads are OpenMP's, up to 64, without CPU affinity, as Arch builds it.
# The kernels for every x86-64 CPU are compiled in and chosen at run time
# (DYNAMIC_ARCH, DYNAMIC_OLDER over the GENERIC baseline, as Debian builds
# it), so the library runs on any x86-64 machine and is fast on new ones.
_openblas_make() {
    make FC=gfortran \
        DYNAMIC_ARCH=1 DYNAMIC_OLDER=1 TARGET=GENERIC \
        USE_OPENMP=1 NUM_THREADS=64 NO_AFFINITY=1 NO_WARMUP=1 \
        NO_STATIC=1 NO_LAPACK=1 NO_LAPACKE=1 \
        PREFIX=/usr \
        "$@"
}

build() {
    # The default target would also build and run the tests.
    _openblas_make libs shared
}

package() {
    _openblas_make DESTDIR="$DESTDIR" install

    local lib
    for lib in blas cblas; do
        ln -s libopenblas.so.0 "$DESTDIR/usr/lib/lib$lib.so"
        ln -s libopenblas.so.0 "$DESTDIR/usr/lib/lib$lib.so.3"
        ln -s openblas.pc "$DESTDIR/usr/lib/pkgconfig/$lib.pc"
    done
}
