# Not in the book: the newest upstream release of netCDF-C, built with
# CMake as its INSTALL says and configured as Arch Linux configures it:
# netCDF-4 (HDF5), DAP2 and DAP4 clients with byte-range access, NCZarr
# with zip stores, and the standard filter plugins (bzip2, blosc, zstd)
# installed in /usr/lib/netcdf/plugin, which the library searches. Off:
# S3 (needs the AWS SDK), SZIP (libaec has no recipe), HDF4, PnetCDF and
# MPI, the tests and examples. The Fortran and C++ bindings are separate
# upstream projects; nothing in joe needs them yet.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_SHARED_LIBS=ON \
        -D NETCDF_ENABLE_NETCDF4=ON \
        -D NETCDF_ENABLE_HDF5=ON \
        -D NETCDF_ENABLE_DAP=ON \
        -D NETCDF_ENABLE_BYTERANGE=ON \
        -D NETCDF_ENABLE_NCZARR=ON \
        -D NETCDF_ENABLE_NCZARR_ZIP=ON \
        -D NETCDF_ENABLE_S3_AWS=OFF \
        -D NETCDF_ENABLE_S3_INTERNAL=OFF \
        -D NETCDF_ENABLE_LIBXML2=ON \
        -D NETCDF_ENABLE_CDF5=ON \
        -D NETCDF_ENABLE_HDF4=OFF \
        -D NETCDF_ENABLE_PNETCDF=OFF \
        -D NETCDF_ENABLE_PLUGINS=ON \
        -D NETCDF_WITH_PLUGIN_DIR=/usr/lib/netcdf/plugin \
        -D NETCDF_PLUGIN_INSTALL=ON \
        -D NETCDF_ENABLE_FILTER_SZIP=OFF \
        -D NETCDF_ENABLE_FILTER_BZ2=ON \
        -D NETCDF_ENABLE_FILTER_BLOSC=ON \
        -D NETCDF_ENABLE_FILTER_ZSTD=ON \
        -D NETCDF_ENABLE_TESTS=OFF \
        -D NETCDF_ENABLE_UNIT_TESTS=OFF \
        -D NETCDF_ENABLE_FILTER_TESTING=OFF \
        -D NETCDF_ENABLE_DAP_REMOTE_TESTS=OFF \
        -D NETCDF_ENABLE_EXAMPLES=OFF \
        -D NETCDF_ENABLE_DOXYGEN=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
