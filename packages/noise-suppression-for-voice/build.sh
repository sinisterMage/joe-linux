# Not in the book: the newest upstream release, built as its README says,
# LADSPA plugin only (/usr/lib/ladspa/librnnoise_ladspa.so), which PipeWire's
# filter-chain and PulseAudio's module-ladspa-sink load.
#
# In this release the LV2, VST2, VST3 and AU plugins are all built with the
# bundled JUCE framework (src/juce_plugin), so they are off: JUCE is large,
# builds its own helper tool and GUI code, and LV2 is no exception here.
# The LADSPA plugin needs nothing but the bundled RNNoise and ladspa.h.
# BUILD_RTCD stays off (upstream's default): it compiles all of RNNoise with
# -mavx2 -mfma, which the compiler may use outside the run-time checked
# paths.
build() {
    cmake -B build -G Ninja \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TESTS=OFF \
        -D BUILD_LADSPA_PLUGIN=ON \
        -D BUILD_LV2_PLUGIN=OFF \
        -D BUILD_VST_PLUGIN=OFF \
        -D BUILD_VST3_PLUGIN=OFF \
        -D BUILD_AU_PLUGIN=OFF \
        -D BUILD_AUV3_PLUGIN=OFF \
        -D BUILD_RTCD=OFF
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
