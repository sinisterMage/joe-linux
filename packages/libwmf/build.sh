# Not in the book: the newest upstream release, built as its INSTALL
# says:
# - libwmf and libwmflite, and the wmf2svg, wmf2eps, wmf2fig and wmf2gd
#   converters; the GD layer uses the copy of GD in src/extra/gd, as
#   libwmf needs its own patched GD (joe has no libgd anyway);
# - libxml2 parses the font map (rather than expat);
# - the X11 device and its wmf2x viewer are left out (--without-x);
# - the GdkPixbuf loader (io-wmf.so) is built, so GTK programs and
#   thumbnailers can show WMF files; gdk-pixbuf's trigger adds it to
#   loaders.cache.
# libwmf installs its own copies of the standard 35 PostScript fonts and
# their font map (usr/share/libwmf/fonts), which cover the fonts WMF files
# name. It can also read Ghostscript's font map, but joe's Ghostscript
# ships no font files for that map to point to, so the Ghostscript paths
# are set to libwmf's own directory (a missing map is skipped quietly);
# otherwise configure would pick a Ghostscript-version-specific path when
# Ghostscript happens to be in the build root.
prepare() {
    patch -Np1 -i /recipe/stdint.patch
}

build() {
    ./configure --prefix=/usr \
        --disable-static \
        --with-libxml2 \
        --with-jpeg \
        --with-png \
        --with-zlib \
        --with-freetype \
        --without-x \
        --without-sys-gd \
        --enable-pixbuf \
        --with-fontdir=/usr/share/libwmf/fonts \
        --with-gsfontdir=/usr/share/libwmf/fonts \
        --with-gsfontmap=/usr/share/libwmf/fonts/Fontmap.GS
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
