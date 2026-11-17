# Not in the book: the newest upstream release, built with its top-level
# CMake project as its README says, as Arch Linux builds it.
#
# GraphBLAS and LAGraph, which build on it, are left out: GraphBLAS is by
# far the largest part of the collection to compile and nothing in joe
# Linux uses either (Arch ships them as a separate package). Everything
# else upstream builds by default is here: SuiteSparse_config, AMD, BTF,
# CAMD, CCOLAMD, COLAMD, CHOLMOD (with its bundled METIS), CXSparse, LDL,
# KLU, UMFPACK, ParU, RBio, SPQR, SPEX and Mongoose. No CUDA, no static
# libraries, no demos; SPEX's Python interface is not built.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D SUITESPARSE_ENABLE_PROJECTS="suitesparse_config;mongoose;amd;btf;camd;ccolamd;colamd;cholmod;cxsparse;ldl;klu;umfpack;paru;rbio;spqr;spex" \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_STATIC_LIBS=OFF \
        -D BLA_VENDOR=Generic \
        -D SUITESPARSE_USE_OPENMP=ON \
        -D SUITESPARSE_USE_CUDA=OFF \
        -D SUITESPARSE_USE_PYTHON=OFF \
        -D SUITESPARSE_DEMOS=OFF \
        -D BUILD_TESTING=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
