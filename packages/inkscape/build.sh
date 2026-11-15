prepare() {
    # The book: build against Poppler 26.05 and later.
    patch -Np1 -i "$SOURCES/inkscape-1.4.4-poppler_fixes-3.patch"
}

build() {
    mkdir build
    cd build
    # The book's options. lib2geom is the copy in the tarball (it is built as
    # a shared library and installed with Inkscape, as the book has it).
    # Stated besides:
    # - libdir, so that nothing can pick lib64;
    # - PDF import with Poppler and its Cairo preview, Little CMS, OpenMP,
    #   gspell, GNU Readline (the shell mode) and X11;
    # - off for want of a recipe: ImageMagick and GraphicsMagick (Raster
    #   extensions), libcdr, libvisio and libwpg (CorelDRAW, Visio and
    #   WordPerfect import), and GtkSourceView 4 (only 5, for GTK 4, exists);
    # - no tests (gtest would otherwise be picked up) and uncompressed
    #   manual pages.
    #
    # The Python extensions (Extensions menu and some import and export
    # formats) need python, lxml and PyGObject, which joe has, but their
    # inkex module also imports NumPy and tinycss2, which joe does not
    # package yet; until then those extensions fail with an import error.
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D WITH_INTERNAL_2GEOM=ON \
        -D ENABLE_POPPLER=ON \
        -D ENABLE_POPPLER_CAIRO=ON \
        -D ENABLE_LCMS=ON \
        -D WITH_OPENMP=ON \
        -D WITH_GSPELL=ON \
        -D WITH_GNU_READLINE=ON \
        -D WITH_X11=ON \
        -D WITH_NLS=ON \
        -D WITH_SVG2=ON \
        -D WITH_IMAGE_MAGICK=OFF \
        -D WITH_GRAPHICS_MAGICK=OFF \
        -D WITH_LIBCDR=OFF \
        -D WITH_LIBVISIO=OFF \
        -D WITH_LIBWPG=OFF \
        -D WITH_GSOURCEVIEW=OFF \
        -D WITH_JEMALLOC=OFF \
        -D ENABLE_BINRELOC=OFF \
        -D BUILD_TESTING=OFF \
        -D WITH_MANPAGE_COMPRESSION=OFF \
        -W no-author \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
