# Following the book's ImageMagick page, but with upstream's newest
# release (7.1.2-35) instead of the book's 7.1.2-13, for the security fixes
# released in between. Its configure options are the same as 7.1.2-13's.
build() {
    # PerlMagick supports gscan2pdf. Keep every nested MakeMaker install in
    # the vendor tree without shared perllocal.pod/.packlist bookkeeping.
    # Every delegate is stated so the build root cannot change the result.
    # - on, because they have recipes: bzip2, zip (libzip), zlib, zstd,
    #   lzma, fftw, fontconfig, freetype, Ghostscript's library, HEIC
    #   (libheif), JPEG, JPEG XL, lcms2, OpenJPEG, OpenEXR, Pango, PNG, raw
    #   camera files (libraw's thread-safe libraw_r), librsvg, TIFF, WebP,
    #   libxml2 and X11, DjVu, JBIG, WMF and Raqm complex text layout;
    # - off, because joe has no recipe: autotrace, Display PostScript, FLIF,
    #   FlashPIX, Liquid Rescale, Ultra HDR and MagickCache (dmr).
    #   jemalloc is the selected allocator; other allocators stay off.
    # - off although graphviz exists: its GVC coder only renders DOT files
    #   and would make ImageMagick depend on all of graphviz.
    # OpenCL stays off (its default).
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --enable-hdri \
        --with-modules \
        --with-perl \
        --with-perl-options='INSTALLDIRS=vendor NO_PERLLOCAL=1 NO_PACKLIST=1' \
        --disable-static \
        --disable-opencl \
        --with-x \
        --with-bzlib \
        --with-zip \
        --with-zlib \
        --with-zstd \
        --with-lzma \
        --with-fftw \
        --with-fontconfig \
        --with-freetype \
        --with-gslib \
        --with-heic \
        --with-jpeg \
        --with-jxl \
        --with-lcms \
        --with-openjp2 \
        --with-openexr \
        --with-pango \
        --with-png \
        --with-raw \
        --with-rsvg \
        --with-tiff \
        --with-webp \
        --with-xml \
        --without-autotrace \
        --without-dps \
        --with-djvu \
        --without-flif \
        --without-fpx \
        --without-gvc \
        --with-jbig \
        --without-lqr \
        --with-raqm \
        --without-uhdr \
        --with-wmf \
        --without-dmr \
        --with-jemalloc \
        --without-tcmalloc \
        --without-umem \
        --without-mtmalloc \
        --with-dejavu-font-dir=/usr/share/fonts/dejavu
    make
}

package() {
    make DESTDIR="$DESTDIR" DOCUMENTATION_PATH=/usr/share/doc/imagemagick-7.1.2 install
    find "$DESTDIR" -type f \( -name .packlist -o -name perllocal.pod \) -delete
}
