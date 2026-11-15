prepare() {
    # The book: upstream's patch for building against gexiv2 0.16.
    patch -Np1 -i build/macos/patches/0001-build-macos-Do-not-require-gexiv2-0.14-on-homebrew.patch
}

build() {
    mkdir gimp-build
    cd gimp-build
    # The book's options, plus every feature it leaves to detection stated:
    # on where joe has the library, off otherwise. No recipe exists for AAlib
    # (ASCII art), cfitsio (FITS), libheif (HEIF/AVIF), libmng, libwmf or
    # libbacktrace. Lua plug-ins need Lua 5.1 with lua-lgi, which joe lacks.
    # The unmaintained WebKit help browser and TWAIN plug-ins stay off, and
    # GIMP does not check for new versions: dave updates it. The
    # gi-docgen reference and the appdata validation test are not built.
    #
    # The help pages (gimp-help, 136 MB) are not installed; GIMP opens the
    # online manual instead.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D headless-tests=disabled \
        -D check-update=no \
        -D enable-default-bin=enabled \
        -D bash-completion=enabled \
        -D libunwind=true \
        -D libbacktrace=false \
        -D alsa=enabled \
        -D cairo-pdf=enabled \
        -D ghostscript=enabled \
        -D gudev=enabled \
        -D linux-input=enabled \
        -D jpeg2000=enabled \
        -D jpeg-xl=enabled \
        -D openexr=enabled \
        -D openmp=enabled \
        -D webp=enabled \
        -D xcursor=enabled \
        -D xpm=enabled \
        -D print=true \
        -D vala=enabled \
        -D javascript=enabled \
        -D lua=false \
        -D aa=disabled \
        -D fits=disabled \
        -D heif=disabled \
        -D mng=disabled \
        -D wmf=disabled \
        -D webkit-unmaintained=false \
        -D twain-unmaintained=false \
        -D appdata-test=disabled \
        -D gi-docgen=disabled
    ninja
}

package() {
    cd gimp-build
    DESTDIR="$DESTDIR" ninja install
}
