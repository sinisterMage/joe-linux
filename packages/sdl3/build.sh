# Following the book's SDL3 page, with its patch, without the test
# library, static library or rpath.
#
# Every driver whose library joe has is on and loaded at run time
# (upstream's default). Switched off because joe has no recipe for them:
# JACK and sndio audio, libthai, liburing (asynchronous I/O falls back to
# a thread pool). OSS is upstream's default (off on Linux).
prepare() {
    patch -Np1 -i "$SOURCES/SDL3-3.4.20-upstream_fixes-1.patch"
}

build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D SDL_TEST_LIBRARY=OFF \
        -D SDL_STATIC=OFF \
        -D SDL_RPATH=OFF \
        -D SDL_DEPS_SHARED=ON \
        -D SDL_X11=ON \
        -D SDL_WAYLAND=ON \
        -D SDL_WAYLAND_LIBDECOR=ON \
        -D SDL_KMSDRM=ON \
        -D SDL_OPENGL=ON \
        -D SDL_OPENGLES=ON \
        -D SDL_VULKAN=ON \
        -D SDL_PIPEWIRE=ON \
        -D SDL_PULSEAUDIO=ON \
        -D SDL_ALSA=ON \
        -D SDL_JACK=OFF \
        -D SDL_SNDIO=OFF \
        -D SDL_HIDAPI_LIBUSB=ON \
        -D SDL_LIBUDEV=ON \
        -D SDL_DBUS=ON \
        -D SDL_IBUS=ON \
        -D SDL_FRIBIDI=ON \
        -D SDL_LIBTHAI=OFF \
        -D SDL_LIBURING=OFF \
        -W no-author -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
