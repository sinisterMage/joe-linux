# Not in the book: the newest SDL 2 release of SDL_image, built with its
# CMake build, configured as distributions configure it:
# - the system libraries for every format joe has (AVIF, JPEG, JPEG XL,
#   PNG, TIFF, WebP), linked directly (SDL2IMAGE_DEPS_SHARED=OFF) so that
#   the dependencies are visible, and none of the copies in external/
#   (SDL2IMAGE_VENDORED=OFF);
# - libjpeg and libpng rather than stb_image (SDL2IMAGE_BACKEND_STB=OFF),
#   which also gives JPEG and PNG saving;
# - BMP, GIF, LBM, PCX, PNM, QOI, SVG (nanosvg), TGA, XCF, XPM and XV are
#   built in.
# SDL2IMAGE_STRICT makes a missing library an error instead of a silently
# missing format. The sample programs (showimage, showanim) are not built.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D SDL2IMAGE_VENDORED=OFF \
        -D SDL2IMAGE_DEPS_SHARED=OFF \
        -D SDL2IMAGE_STRICT=ON \
        -D SDL2IMAGE_BACKEND_STB=OFF \
        -D SDL2IMAGE_SAMPLES=OFF \
        -D SDL2IMAGE_TESTS=OFF \
        -D SDL2IMAGE_AVIF=ON \
        -D SDL2IMAGE_JPG=ON \
        -D SDL2IMAGE_JXL=ON \
        -D SDL2IMAGE_PNG=ON \
        -D SDL2IMAGE_TIF=ON \
        -D SDL2IMAGE_WEBP=ON
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
