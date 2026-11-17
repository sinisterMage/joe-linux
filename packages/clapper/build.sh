# Not in the book: the newest upstream release, built with meson as its
# README describes. Upstream publishes no checksum for the source archive.
# NewsFlash links libclapper and libclapper-gtk.
build() {
    mkdir build
    cd build
    # Every part upstream builds by default (the libraries, the GStreamer
    # plugin with its GL importers, the application, introspection and
    # vapi), stated so that it does not depend on the build root, plus:
    # - enhancers-loader needs libpeas 2, which does not exist here.
    # - server (remote control) needs libmicrodns, which does not exist here.
    # - rawimporter is left to upstream's default: it is only built when
    #   the GL uploader is not.
    # - doc needs gi-docgen.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D clapper=enabled \
        -D clapper-gtk=enabled \
        -D clapper-app=enabled \
        -D gst-plugin=enabled \
        -D introspection=enabled \
        -D vapi=enabled \
        -D doc=false \
        -D enhancers-loader=disabled \
        -D pipeline-preview=enabled \
        -D discoverer=enabled \
        -D mpris=enabled \
        -D server=disabled \
        -D glimporter=enabled \
        -D gluploader=enabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
