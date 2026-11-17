build() {
    mkdir build
    cd build
    # The book uses the defaults. Stated here, on where a recipe exists:
    # introspection and Vala bindings (GIMP's plug-in API is built on them),
    # OpenMP, RAW and the operations for the image libraries joe has.
    # Off because their dependencies have no recipe: Jasper, lensfun,
    # libspiro, mrg, maxflow and SDL 1. Graphviz's dot renders the introspect
    # operation's graphs at run time. LuaJIT installs the Lua bindings;
    # Video4Linux, SDL 2/3 and UMFPACK enable their operations.
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
        -D graphviz=enabled \
        -D jasper=disabled \
        -D lensfun=disabled \
        -D libav=disabled \
        -D libraw=enabled \
        -D libspiro=disabled \
        -D libv4l=enabled \
        -D libv4l2=enabled \
        -D lua=enabled \
        -D mrg=disabled \
        -D maxflow=disabled \
        -D umfpack=enabled \
        -D sdl1=disabled \
        -D sdl2=enabled \
        -D sdl3=enabled \
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
