build() {
    mkdir build
    cd build
    # The book uses the defaults. Stated here, on where a recipe exists:
    # introspection and Vala bindings (GIMP's plug-in API is built on them),
    # OpenMP, and the operations for the image libraries joe has. Off
    # because joe has no recipe for what they need: Graphviz, Jasper,
    # lensfun, libraw, libspiro, v4l, LuaJIT, mrg, maxflow, UMFPACK and SDL.
    # FFmpeg (libav) is off, as upstream has it: the book says it is broken.
    # gexiv2 is off: this release looks for the 0.14 API (gexiv2.pc), and
    # joe's gexiv2 is 0.16, a new API, so the book's build goes without it
    # too. Only the gegl program used it, for image metadata.
    # libnsgif and poly2tri-c are the copies in subprojects/. The
    # experimental operations ("workshop") and the docs are not built.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D introspection=true \
        -D vapigen=enabled \
        -D openmp=enabled \
        -D cairo=enabled \
        -D pango=enabled \
        -D pangocairo=enabled \
        -D gdk-pixbuf=enabled \
        -D gexiv2=disabled \
        -D lcms=enabled \
        -D librsvg=enabled \
        -D libtiff=enabled \
        -D openexr=enabled \
        -D poppler=enabled \
        -D webp=enabled \
        -D graphviz=disabled \
        -D jasper=disabled \
        -D lensfun=disabled \
        -D libav=disabled \
        -D libraw=disabled \
        -D libspiro=disabled \
        -D libv4l=disabled \
        -D libv4l2=disabled \
        -D lua=disabled \
        -D mrg=disabled \
        -D maxflow=disabled \
        -D umfpack=disabled \
        -D sdl1=disabled \
        -D sdl2=disabled \
        -D sdl3=disabled \
        -D pygobject=disabled \
        -D workshop=false \
        -D docs=false \
        -D gtk-doc=false \
        -D gi-docgen=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
