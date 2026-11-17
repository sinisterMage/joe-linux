# Following the book's GLU page. GLEW's headers and pkg-config file require
# it. gl_provider=gl: Mesa's libGL, since joe has no libglvnd.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gl_provider=gl \
        --default-library=shared
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
