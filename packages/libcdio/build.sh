# The book's commands (multimedia/libcdio) for the newest upstream release:
# the book's 2.1.0 (2019) lacks udf_setpos, which Impression uses, and
# upstream now releases on GitHub. libcdio-paranoia is not built; nothing
# here needs it. Stated rather than detected: CDDB lookups in cd-info
# need libcddb and Video CD information needs libvcdinfo, neither of which
# has a recipe.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-cddb \
        --disable-vcd-info
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
