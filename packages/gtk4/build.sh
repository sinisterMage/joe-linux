build() {
    mkdir build
    cd build
    # Everything optional is stated so that the build root cannot change the
    # result:
    # - vulkan: the loader and glslc provide the Vulkan renderer.
    # - media-gstreamer: GtkVideo and GtkMediaFile through GstPlay.
    # - print-cups and colord: printer discovery, output and colour profiles.
    #   CPDB is not packaged; the CUPS and print-to-file backends are built.
    # - cloudproviders, tracker: libcloudproviders and tinysparql exist; the
    #   file chooser gains cloud locations and search.
    # - sysprof, accesskit: do not exist here.
    # - demos, tests, examples: not shipped (gtk4-demo, gtk4-widget-factory,
    #   gtk4-node-editor, gtk4-print-editor). gtk4-update-icon-cache,
    #   gtk4-builder-tool, gtk4-launch and the other tools are always built.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D x11-backend=true \
        -D wayland-backend=true \
        -D broadway-backend=true \
        -D media-gstreamer=enabled \
        -D print-cups=enabled \
        -D print-cpdb=disabled \
        -D vulkan=enabled \
        -D cloudproviders=enabled \
        -D tracker=enabled \
        -D colord=enabled \
        -D sysprof=disabled \
        -D accesskit=disabled \
        -D introspection=enabled \
        -D documentation=false \
        -D screenshots=false \
        -D man-pages=false \
        -D build-demos=false \
        -D build-testsuite=false \
        -D build-examples=false \
        -D build-tests=false
    ninja
}

package() {
    cd build
    # The media and print backends are compiled into libgtk-4 in this
    # version: there is no module directory and so no module cache to keep.
    # The GSettings schemas are compiled by glib's trigger and the icon caches
    # by gtk3's.
    DESTDIR="$DESTDIR" ninja install
}
