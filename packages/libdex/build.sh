# Not in the book: the newest upstream release, built with meson as its
# README says.
build() {
    mkdir build
    cd build
    # - liburing: io_uring support needs liburing, which has no recipe.
    # - sysprof: profiling marks need libsysprof-capture, which has no
    #   recipe.
    # - gdbus: the DexDBus helpers and the gdbus-codegen extension that
    #   generates future-returning D-Bus proxies (glib's gdbus-codegen
    #   takes extensions).
    # - pygobject: installs the Dex override module into site-packages; it
    #   is a plain Python file, used only when PyGObject imports Dex.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D introspection=enabled \
        -D vapi=true \
        -D liburing=disabled \
        -D sysprof=false \
        -D eventfd=enabled \
        -D gdbus=enabled \
        -D pygobject=true \
        -D docs=false \
        -D examples=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
