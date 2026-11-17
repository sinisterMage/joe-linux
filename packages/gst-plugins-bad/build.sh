# GTK 4 needs libgstplay-1.0 (gstreamer-play-1.0) for its media backend, and
# that library lives here.

build() {
    mkdir build
    cd build

    # Disable automatic features, then name the enabled plugins and their
    # dependencies explicitly. GstPlay and the other gst-libs are always
    # built. GPL is needed for DVD navigation and the x265 encoder.
    # VA-API, Vulkan, OpenGL and Orc remain off in this plugin set.
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
        -D gpl=enabled \
        -D assrender=enabled \
        -D svtav1=enabled \
        -D webrtcdsp=enabled \
        -D openh264=enabled \
        -D fluidsynth=enabled \
        -D chromaprint=enabled \
        -D resindvd=enabled \
        -D srt=enabled \
        -D rist=enabled \
        -D aom=enabled \
        -D x265=enabled \
        -D v4l2codecs=enabled \
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
