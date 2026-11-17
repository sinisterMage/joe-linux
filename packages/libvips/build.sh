# Not in the book: the newest upstream release, built with meson as its
# README describes. Every loader and saver whose library joe has is on;
# the HEIF, JPEG XL, ImageMagick and poppler ones are built as modules
# (upstream's default), so libvips itself does not link those libraries.
# SIMD through highway (orc is the older alternative, not packaged).
# ImageMagick (MagickCore 7) loads and saves the formats nothing else
# handles; GIF is also saved through it, as cgif has no recipe.
#
# Switched off because joe has no recipe for what they need: cfitsio (FITS),
# cgif, libspng (libpng is used), libultrahdr (UltraHDR JPEG), matio
# (MATLAB), nifti, OpenSlide, PDFium (poppler is used), orc and quantizr
# (libimagequant is used). The example programs and documentation are not
# built; the command-line tools (vips, vipsheader, vipsedit,
# vipsthumbnail) are.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D deprecated=true \
        -D examples=false \
        -D cplusplus=true \
        -D docs=false \
        -D cpp-docs=false \
        -D modules=enabled \
        -D introspection=enabled \
        -D vapi=false \
        -D archive=enabled \
        -D exif=enabled \
        -D fftw=enabled \
        -D fontconfig=enabled \
        -D heif=enabled \
        -D imagequant=enabled \
        -D jpeg=enabled \
        -D jpeg-xl=enabled \
        -D lcms=enabled \
        -D magick=enabled \
        -D openexr=enabled \
        -D openjpeg=enabled \
        -D highway=enabled \
        -D pangocairo=enabled \
        -D png=enabled \
        -D poppler=enabled \
        -D raw=enabled \
        -D rsvg=enabled \
        -D tiff=enabled \
        -D webp=enabled \
        -D zlib=enabled \
        -D cfitsio=disabled \
        -D cgif=disabled \
        -D matio=disabled \
        -D nifti=disabled \
        -D openslide=disabled \
        -D orc=disabled \
        -D pdfium=disabled \
        -D quantizr=disabled \
        -D spng=disabled \
        -D uhdr=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
