# Not in the book: the newest upstream release, built from its source
# archive (which carries every module, so no "make fetch") as its README
# says. Only the LV2 plugins without their own interfaces are built
# (FEATURES=lv2): that is what LV2 hosts such as EasyEffects load, and it
# keeps out the OpenGL/X11 toolkit, the JACK and PipeWire standalone
# programs, the CLAP, VST, LADSPA and GStreamer wrappers, and the HTML
# documentation (which needs PHP). The code for SSE, AVX and AVX-512 is
# built for every x86-64 processor and chosen at run time.
build() {
    make config PREFIX=/usr LIBDIR=/usr/lib FEATURES='lv2' VERBOSE=1
    make VERBOSE=1
}

package() {
    make install DESTDIR="$DESTDIR" VERBOSE=1
}
