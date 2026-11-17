# Following the book's libheif page.
build() {
    # The book's options (no gdk-pixbuf loader, no OpenH264 decoder), plus
    # every codec stated, so the result does not depend on the build root:
    # - on, because they have recipes: libde265, x265, x264, libaom (both
    #   ways), dav1d, OpenJPEG and libjpeg-turbo;
    # - off: SVT-AV1 (AV1 encoding is libaom's here), FFmpeg's decoder (it
    #   duplicates libde265 and would put all of FFmpeg under every user of
    #   libheif), and kvazaar, uvg266, vvdec, vvenc, rav1e and OpenJPH,
    #   which have no recipe;
    # - heif-view needs SDL2, which has no recipe;
    # - the uncompressed (ISO 23001-17) codec and header compression stay
    #   off, as upstream ships them.
    # Codecs that upstream builds as plugins by default (dav1d, OpenJPEG)
    # go to /usr/lib/libheif.
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTING=OFF \
        -D BUILD_DOCUMENTATION=OFF \
        -D WITH_GDK_PIXBUF=OFF \
        -D WITH_EXAMPLES=ON \
        -D WITH_EXAMPLE_HEIF_THUMB=ON \
        -D WITH_EXAMPLE_HEIF_VIEW=OFF \
        -D WITH_LIBDE265=ON \
        -D WITH_X265=ON \
        -D WITH_X264=ON \
        -D WITH_AOM_DECODER=ON \
        -D WITH_AOM_ENCODER=ON \
        -D WITH_DAV1D=ON \
        -D WITH_OpenJPEG_DECODER=ON \
        -D WITH_OpenJPEG_ENCODER=ON \
        -D WITH_JPEG_DECODER=ON \
        -D WITH_JPEG_ENCODER=ON \
        -D WITH_OpenH264_DECODER=OFF \
        -D WITH_SvtEnc=OFF \
        -D WITH_FFMPEG_DECODER=OFF \
        -D WITH_KVAZAAR=OFF \
        -D WITH_UVG266=OFF \
        -D WITH_VVDEC=OFF \
        -D WITH_VVENC=OFF \
        -D WITH_RAV1E=OFF \
        -D WITH_OPENJPH_ENCODER=OFF \
        -D WITH_UNCOMPRESSED_CODEC=OFF \
        -D WITH_HEADER_COMPRESSION=OFF \
        -D WITH_LIBSHARPYUV=ON \
        -D WITH_GEOTIFF=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
