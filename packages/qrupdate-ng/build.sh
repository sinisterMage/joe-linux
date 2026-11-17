# Not in the book: newest upstream stable, following its CMake instructions.
build() {
    cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=OFF \
        -DQRUPDATE_C_INTERFACE=ON -DQRUPDATE_DOCS=OFF \
        -DBLA_VENDOR=Generic -DBLA_SIZEOF_INTEGER=4 \
        -DBLAS_LIBRARIES=/usr/lib/libopenblas.so \
        '-DLAPACK_LIBRARIES=/usr/lib/liblapack.so;/usr/lib/libopenblas.so' 
    cmake --build build -j"$JOBS"
}

package() {
    DESTDIR="$DESTDIR" cmake --install build
}
