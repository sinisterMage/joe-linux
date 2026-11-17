# Not in the book: newest stable upstream release, following its Meson build.
prepare() {
    # Modern FFmpeg no longer derives stream parameters from the deprecated
    # second argument of avformat_new_stream(). Populate them explicitly.
    patch -Np1 -i /recipe/ffmpeg-stream-parameters.patch
}

build() {
    meson setup build --prefix=/usr --libdir=lib --buildtype=release
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
