# Not in the book: the newest upstream release, built as its INSTALL says,
# with the terminals Arch Linux builds where joe has what they need: the Qt
# window (joe's Qt 6 has every module gnuplot_qt uses), the X11 window, the
# cairo terminals (pngcairo, pdfcairo, epscairo, cairolatex, webp) and the
# bitmap ones.
#
# Off: the wxt window, because the Qt window does the same job and one
# interactive toolkit is enough; the lua/TikZ terminal, which only makes
# sense with a TeX installation joe does not have (nor its LaTeX style
# files); libgd (png/gif/jpeg terminals), libcerf, libamos and libcaca,
# which have no recipes.
build() {
    # Autoconf 2.72's C++11 probe assigns a u8"" literal to const char *,
    # which C++20 (GCC 16's default) rejects, so configure would fall back
    # to -std=gnu++11; Qt 6 needs C++17. The compiler's default needs no flag.
    ac_cv_prog_cxx_cxx11= \
    ./configure --prefix=/usr \
        --with-readline=gnu \
        --with-qt=qt6 \
        --with-cairo \
        --with-x \
        --with-bitmap-terminals \
        --disable-wxwidgets \
        --without-lua \
        --without-latex \
        --without-gd \
        --without-libcerf \
        --without-amos \
        --without-caca
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
