# Not in the book: the newest upstream release, built with its GNU build
# files (Project/GNU/Library) as its ReadMe says.
#
# libcurl is linked for URLs. libmms (MMS streams) has no recipe. Graphviz
# is loaded at run time, only for the graph output (--Output=Graph_*), so
# it is not a dependency. tinyxml2 and the hash libraries are the bundled
# copies (no system tinyxml2 exists).
build() {
    cd Project/GNU/Library
    sh ./autogen.sh
    ./configure --prefix=/usr \
        --enable-shared \
        --disable-static \
        --with-libcurl \
        --without-libmms \
        --with-graphviz=runtime \
        --without-libtinyxml2
    make
}

package() {
    cd Project/GNU/Library
    make DESTDIR="$DESTDIR" install
}
