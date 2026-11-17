# Following the book's MuPDF page.
_mupdf_config() {
    # The book's choice of system libraries, except for the ones joe has
    # no recipe for: freeglut (mupdf-gl uses the copy in the tarball);
    # jbig2dec and MuJS are built from their copies as in the book, and
    # lcms2mt is preferred to lcms2 by upstream. Plus, as their
    # libraries have recipes: OCR with the system Tesseract and leptonica
    # (tesseract=yes), and comic-book archives through libarchive
    # (archive=yes). Barcodes would need zxing-cpp and zint, which have
    # no recipe. Everything is in user.make, which the Makefile reads, so
    # "make install" sees the same configuration as "make".
    cat > user.make <<EOT
build := release
shared := yes
verbose := yes
prefix := /usr
docdir := /usr/share/doc/mupdf-1.26.12
SO_INSTALL_MODE := 755
tesseract := yes
archive := yes
barcode := no
USE_SYSTEM_BROTLI := yes
USE_SYSTEM_FREETYPE := yes
USE_SYSTEM_HARFBUZZ := yes
USE_SYSTEM_JBIG2DEC := no
USE_SYSTEM_JPEGXR := no
USE_SYSTEM_LCMS2 := no
USE_SYSTEM_LIBJPEG := yes
USE_SYSTEM_MUJS := no
USE_SYSTEM_OPENJPEG := yes
USE_SYSTEM_ZLIB := yes
USE_SYSTEM_GLUT := no
USE_SYSTEM_CURL := yes
USE_SYSTEM_GUMBO := yes
USE_SYSTEM_LEPTONICA := yes
USE_SYSTEM_TESSERACT := yes
USE_SYSTEM_ZXINGCPP := no
EOT
}

prepare() {
    _mupdf_config
}

build() {
    XCFLAGS=-fPIC make
}

package() {
    XCFLAGS=-fPIC make DESTDIR="$DESTDIR" install
    # install-libs already links libmupdf.so.26 and libmupdf.so to
    # libmupdf.so.26.12, which the book does by hand.
    ln -sfv mupdf-x11 "$DESTDIR/usr/bin/mupdf"
}
