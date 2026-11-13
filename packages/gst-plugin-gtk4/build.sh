# There is no book page. This is gtk4paintablesink, the one plugin of
# gst-plugins-rs that Showtime (and any GTK 4 video player) needs; 0.15 is the
# series that goes with GStreamer 1.28. Built the way gst-plugins-rs documents
# for a single plugin: cargo-c (cargo cbuild / cinstall).

# Features:
# - wayland: zero-copy GL textures on Wayland. The X11 variants (x11egl,
#   x11glx) are left out: the desktop is Wayland only, and under X11 the sink
#   still works by uploading frames.
# - dmabuf: hand DMA-BUF frames from hardware decoders to GTK directly.
# - gtk_v4_20, v1_28: use the newest GTK and GStreamer API the crate knows.
_capi_args=(--release --locked --prefix=/usr --libdir=/usr/lib
    --library-type=cdylib
    --features wayland,dmabuf,gtk_v4_20,v1_28)

build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    cargo cbuild "${_capi_args[@]}"
}

package() {
    export CARGO_HOME="$PWD/.cargo-home"
    cargo cinstall "${_capi_args[@]}" --destdir="$DESTDIR"
    # The pkg-config file only serves static linking of the plugin.
    rm -rf "$DESTDIR/usr/lib/gstreamer-1.0/pkgconfig" "$DESTDIR/usr/lib/pkgconfig"
}
