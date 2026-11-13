prepare() {
    # Enable the GX/AAT and OpenType table validation modules.
    sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

    # Enable subpixel (LCD) rendering.
    sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
        -i include/freetype/config/ftoption.h
}

build() {
    # --with-harfbuzz=dynamic needs no HarfBuzz at build time and does not
    # link against it: FreeType carries the declarations it needs and
    # dlopen()s libharfbuzz.so the first time the auto-hinter wants it, doing
    # without if the library is not there. So FreeType is built once, before
    # HarfBuzz, and gains HarfBuzz auto-hinting when HarfBuzz is installed.
    #
    # The other libraries are auto-detected by default; name them so that
    # the result does not depend on what happens to be in the build root.
    # librsvg is only used by the demo programs, which are not part of this
    # tarball.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-freetype-config \
        --with-harfbuzz=dynamic \
        --with-zlib=yes \
        --with-bzip2=yes \
        --with-png=yes \
        --with-brotli=yes \
        --with-librsvg=no
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
