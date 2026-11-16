# Following the book's Graphviz page, with every optional component stated.
# Off because joe Linux has no recipe for what they need: GD, GTS (better
# neato and sfdp placement), ANN (mingle), DevIL, LASi, AAlib, and smyrna
# (GtkGLExt, freeglut). Also off: the Qt editor gvedit, the Tcl packages and
# the SWIG language bindings.
prepare() {
    sed '/ORIGIN/d' -i lib/CMakeLists.txt
}

build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_LTDL=ON \
        -D WITH_EXPAT=ON \
        -D WITH_ZLIB=ON \
        -D WITH_GDK=ON \
        -D WITH_GHOSTSCRIPT=ON \
        -D WITH_POPPLER=ON \
        -D WITH_RSVG=ON \
        -D WITH_WEBP=ON \
        -D WITH_X=ON \
        -D WITH_GTK=OFF \
        -D WITH_SMYRNA=OFF \
        -D WITH_GVEDIT=OFF \
        -D WITH_QUARTZ=OFF \
        -D ENABLE_TCL=OFF \
        -D ENABLE_SWIG=OFF \
        -D ENABLE_SHARP=OFF \
        -D ENABLE_D=OFF \
        -D ENABLE_GO=OFF \
        -D ENABLE_GUILE=OFF \
        -D ENABLE_JAVA=OFF \
        -D ENABLE_JAVASCRIPT=OFF \
        -D ENABLE_LUA=OFF \
        -D ENABLE_PERL=OFF \
        -D ENABLE_PHP=OFF \
        -D ENABLE_PYTHON=OFF \
        -D ENABLE_R=OFF \
        -D ENABLE_RUBY=OFF \
        -D with_cxx_api=OFF \
        -D with_cxx_tests=OFF \
        ..
    # Uncompressed manual pages, as the book has them.
    sed -i '/GZIP/s/:.*$/=/' CMakeCache.txt
    make
}

package() {
    cd build
    make DESTDIR="$DESTDIR" install

    # dot finds its plugins through a configuration file that "dot -c"
    # writes into the plugin directory; it is rebuilt whenever the plugins
    # change rather than packaged. The install step already ran it into
    # DESTDIR; a packaged copy would be sealed, and the trigger could not
    # rewrite it.
    rm "$DESTDIR/usr/lib/graphviz/config8"
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/46-graphviz-plugins.zon" <<'EOT'
.{
    .name = "Graphviz plugin configuration",
    .paths = .{"usr/lib/graphviz/"},
    .exec = .{ "/usr/bin/dot", "-c" },
}
EOT
}
