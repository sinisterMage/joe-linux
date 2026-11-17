# Not in the book: newest upstream stable, following GDAL CMake documentation.
# Start external autodetection OFF and allow only the declared libraries below.
# Optional codecs/drivers without packaged SDKs stay OFF, including proprietary formats,
# Arrow/Parquet, TileDB, HDF4, Spatialite, SFCGAL, MongoDB, Oracle, and MPI.
# All built-in formats and drivers supported by the enabled system libraries are built.
# Python SWIG bindings use system NumPy headers (3.15 ABI); Java/.NET wrappers stay off.
build() {
    cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF \
        -DBUILD_APPS=ON -DBUILD_PYTHON_BINDINGS=ON -DBUILD_PYTHON_STUBS=OFF \
        -DBUILD_JAVA_BINDINGS=OFF -DBUILD_CSHARP_BINDINGS=OFF \
        -DGDAL_PYTHON_INSTALL_PREFIX=/usr \
        -DGDAL_PYTHON_INSTALL_LIB=/usr/lib/python3.15/site-packages \
        -DGDAL_USE_EXTERNAL_LIBS=OFF -DGDAL_USE_INTERNAL_LIBS=OFF \
        -DGDAL_BUILD_OPTIONAL_DRIVERS=ON -DOGR_BUILD_OPTIONAL_DRIVERS=ON \
        -DGDAL_ENABLE_PLUGINS=OFF -DGDAL_ENABLE_PLUGINS_NO_DEPS=OFF \
        -DGDAL_USE_ZLIB=ON \
        -DGDAL_USE_PROJ=ON \
        -DGDAL_USE_CURL=ON \
        -DGDAL_USE_ICONV=ON \
        -DGDAL_USE_LIBXML2=ON \
        -DGDAL_USE_EXPAT=ON \
        -DGDAL_USE_DEFLATE=ON \
        -DGDAL_USE_OPENSSL=ON \
        -DGDAL_USE_TIFF=ON \
        -DGDAL_USE_GEOTIFF=ON \
        -DGDAL_USE_JPEG=ON \
        -DGDAL_USE_PNG=ON \
        -DGDAL_USE_GIF=ON \
        -DGDAL_USE_WEBP=ON \
        -DGDAL_USE_OPENJPEG=ON \
        -DGDAL_USE_ZSTD=ON \
        -DGDAL_USE_JSONC=ON \
        -DGDAL_USE_QHULL=ON \
        -DGDAL_USE_PCRE2=ON \
        -DGDAL_USE_SQLITE3=ON \
        -DGDAL_USE_HDF5=ON \
        -DGDAL_USE_NETCDF=ON \
        -DGDAL_USE_GEOS=ON \
        -DGDAL_USE_LIBLZMA=ON \
        -DGDAL_USE_LZ4=ON \
        -DGDAL_USE_BLOSC=ON \
        -DGDAL_USE_ARCHIVE=ON \
        -DGDAL_USE_OPENMP=ON \
        -DGDAL_USE_JXL=ON \
        -DGDAL_USE_JXL_THREADS=ON \
        -DGDAL_USE_OPENEXR=ON \
        -DGDAL_USE_HEIF=ON \
        -DGDAL_USE_AVIF=ON \
        -DGDAL_USE_POPPLER=ON \
        -DGDAL_USE_ODBC=ON \
        -DGDAL_USE_MYSQL=ON \
        -DGDAL_USE_POSTGRESQL=ON
    cmake --build build -j"$JOBS"
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
