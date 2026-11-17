# Not in the book: the newest release of the 1.x series, built as its README
# says. The name is that of its pkg-config module and library
# (webrtc-audio-processing-1, libwebrtc-audio-processing-1.so); 2.x is a
# different API (webrtc-audio-processing-2) that installs beside it.

prepare() {
    # GCC 15 and later no longer include <cstdint> through other standard
    # headers; these use the fixed-width integer types without including
    # it. The same fix is upstream (e9c78dc) for 2.x.
    local f
    for f in webrtc/api/task_queue/task_queue_base.h:'#include <memory>' \
        webrtc/rtc_base/trace_event.h:'#include <string>' \
        webrtc/rtc_base/system/file_wrapper.h:'#include <string>'; do
        grep -qx "${f#*:}" "${f%%:*}"
        sed -i "0,\|^${f#*:}\$|s||&\n#include <cstdint>|" "${f%%:*}"
        grep -qx '#include <cstdint>' "${f%%:*}"
    done
}

build() {
    mkdir build
    cd build
    # C++17 is meson.build's default and what this release is written for.
    # abseil-cpp was built as C++20 (its installed options.h pins the C++20
    # std ordering and source_location types), but the Abseil
    # headers this code includes (optional, string_view, type_traits,
    # attributes) are the same under C++17: absl::optional and
    # absl::string_view are the std types either way. Abseil comes from the
    # system: no fallback to the bundled wrap.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D cpp_std=c++17
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
