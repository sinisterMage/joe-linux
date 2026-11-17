# Not in the book: the newest upstream release, built with CMake (the only
# build system since HDF5 2.0) as its INSTALL_CMake.md says and as Arch
# Linux builds it: the C, C++, Fortran and high-level libraries, the tools,
# the deflate filter (zlib). Off: the SZIP filter (libaec has no recipe),
# Java (it would make every HDF5 user carry a JDK), MPI, plugin filters
# (they are downloaded), examples, tests, static libraries. The CMake
# package goes to /usr/lib/cmake/hdf5, as Arch puts it, and the "data"
# directory to /usr/share/hdf5: upstream would install its LICENSE as
# /usr/share/LICENSE.
build() {
    cmake -S "hdf5-$PKG_VERSION" -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D HDF5_USE_GNU_DIRS=ON \
        -D HDF5_INSTALL_CMAKE_DIR=lib/cmake/hdf5 \
        -D HDF5_INSTALL_DATA_DIR=share/hdf5 \
        -D BUILD_SHARED_LIBS=ON \
        -D BUILD_STATIC_LIBS=OFF \
        -D HDF5_BUILD_HL_LIB=ON \
        -D HDF5_BUILD_CPP_LIB=ON \
        -D HDF5_BUILD_FORTRAN=ON \
        -D HDF5_BUILD_JAVA=OFF \
        -D HDF5_BUILD_TOOLS=ON \
        -D HDF5_BUILD_EXAMPLES=OFF \
        -D HDF5_BUILD_DOC=OFF \
        -D BUILD_TESTING=OFF \
        -D HDF5_ENABLE_ZLIB_SUPPORT=ON \
        -D HDF5_ENABLE_SZIP_SUPPORT=OFF \
        -D HDF5_ENABLE_PLUGIN_SUPPORT=OFF \
        -D HDF5_ENABLE_PARALLEL=OFF \
        -D HDF5_ALLOW_EXTERNAL_SUPPORT=NO
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
