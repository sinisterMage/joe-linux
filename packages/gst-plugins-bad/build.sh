# GTK 4 needs libgstplay-1.0 (gstreamer-play-1.0) for its media backend, and
# that library lives here.

build() {
    mkdir build
    cd build

    # This package has some two hundred automatic features, most of them
    # wrappers around libraries that do not exist here. All of them are
    # switched off, and the ones without any outside dependency that a desktop
    # uses are switched on again by name, so that the build root cannot change
    # the result. The libraries under gst-libs (play, player, codecparsers,
    # mpegts, transcoder ...) are not features and are always built.
    #
    # Not built in particular: everything GPL (the book's -D gpl=enabled only
    # matters for x265, faad, dts, mpeg2enc, mplex and resindvd), the Wayland,
    # VA-API, Vulkan and OpenGL elements, and Orc acceleration.
    local plugin plugins=()
    for plugin in adpcmdec adpcmenc aiff asfmux audiobuffersplit audiofxbad \
        audiolatency audiomixmatrix audiovisualizers autoconvert bayer \
        camerabin2 codecalpha codectimestamper coloreffects debugutils \
        dvbsubenc dvdspu fieldanalysis freeverb gaudieffects gdp \
        geometrictransform id3tag insertbin inter interlace ivfparse ivtc \
        jp2kdecimator jpegformat midi mpegdemux mpegpsmux mpegtsdemux \
        mpegtsmux mxf pcapparse pnm proxy rawparse removesilence rtp sdp \
        segmentclip siren smooth speed subenc switchbin unixfd videofilters \
        videoframe_audiolevel videoparsers videosignal vmnc; do
        plugins+=(-D "$plugin=enabled")
    done

    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D auto_features=disabled \
        "${plugins[@]}" \
        -D introspection=enabled \
        -D nls=enabled \
        -D package-name="GStreamer Bad Plugins (joe Linux)" \
        -D package-origin="https://gstreamer.freedesktop.org/"
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
