prepare() {
    # Do not write a run-time library search path into the programs.
    sed -i -e 's/^\(\s*hardcode_libdir_flag_spec\s*=\).*/\1/' configure
}

build() {
    # The book's options. The file reader stays lame's own (libsndfile is
    # the book's optional alternative), and the GTK 1 frame analyser is not
    # looked for. --enable-nasm only matters on 32-bit x86.
    ./configure --prefix=/usr \
        --enable-mp3rtp \
        --disable-static \
        --with-fileio=lame \
        --disable-gtktest
    make
}

package() {
    make pkghtmldir=/usr/share/doc/lame-3.100 DESTDIR="$DESTDIR" install
}
