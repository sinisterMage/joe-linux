# Not in the book: built with upstream's CMakeLists.txt, as Debian builds
# it. Upstream's shared library has no soname; like Debian's it gets
# libyuv.so.0 (upstream keeps the ABI of its C functions). The static
# library is not shipped. yuvconvert, the conversion tool upstream
# installs, is.
prepare() {
    sed -i '/set_target_properties( ${ly_lib_shared} PROPERTIES PREFIX "lib" )/a set_target_properties( ${ly_lib_shared} PROPERTIES SOVERSION 0 )' \
        CMakeLists.txt
    grep -q 'PROPERTIES SOVERSION 0' CMakeLists.txt
}

build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_BUILD_TYPE=Release \
        -D UNIT_TEST=OFF \
        -D LIBYUV_DISABLE_JPEG=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
    rm "$DESTDIR/usr/lib/libyuv.a"
}
