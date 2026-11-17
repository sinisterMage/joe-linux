# Following the book's mpv page, with every feature that has a library on
# Linux stated so that the build root cannot change the result.
#
# On: libmpv (celluloid uses it) and the mpv program; Lua scripting with
# LuaJIT (the on-screen controller and other built-in scripts); FFmpeg's
# libavdevice; libarchive (archives as playlists); libcurl; Little CMS;
# JPEG screenshots; uchardet (subtitle encodings); zlib; iconv; DVD
# playback (libdvdnav), DVD-Audio (libdvdread) and DVB (kernel headers
# only); ALSA, PipeWire and PulseAudio output; Wayland (with the
# dmabuf-wayland output), X11 (with xv and the X11 clipboard) and DRM/GBM;
# EGL on all three; VA-API decoding on all three; libplacebo through
# OpenGL and Vulkan (vo=gpu and vo=gpu-next); C plugins; the manual page.
# SDL2 supplies gamepad input and alternative audio/video outputs; OpenAL
# is an alternative audio output.
#
# Off:
# - shaderc and SPIRV-Cross: mpv 0.42 only uses these directly for Windows
#   D3D11. On Linux, Vulkan shader compilation belongs to libplacebo.
# - VDPAU, CUDA (ffnvcodec), GLX (gl-x11, the legacy X11 OpenGL path; EGL
#   is used on X11 instead).
# - JavaScript (MuJS), Rubber Band, zimg, VapourSynth, Blu-ray (libbluray),
#   CD audio (libcdio-paranoia), JACK, sndio, libcaca, libsixel and
#   subrandr: no recipes. OSS is obsolete.
# - build-date: keeps the build reproducible.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D gpl=true \
        -D cplayer=true \
        -D libmpv=true \
        -D build-date=false \
        -D tests=false \
        -D fuzzers=false \
        -D cplugins=enabled \
        -D lua=luajit \
        -D javascript=disabled \
        -D libavdevice=enabled \
        -D libarchive=enabled \
        -D libcurl=enabled \
        -D lcms2=enabled \
        -D jpeg=enabled \
        -D uchardet=enabled \
        -D zlib=enabled \
        -D iconv=enabled \
        -D dvdnav=enabled \
        -D dvda=enabled \
        -D dvbin=enabled \
        -D cdda=disabled \
        -D libbluray=disabled \
        -D rubberband=disabled \
        -D zimg=disabled \
        -D vapoursynth=disabled \
        -D subrandr=disabled \
        -D alsa=enabled \
        -D pipewire=enabled \
        -D pulse=enabled \
        -D jack=disabled \
        -D openal=enabled \
        -D sndio=disabled \
        -D oss-audio=disabled \
        -D sdl2-audio=enabled \
        -D sdl2-video=enabled \
        -D sdl2-gamepad=enabled \
        -D wayland=enabled \
        -D dmabuf-wayland=enabled \
        -D x11=enabled \
        -D x11-clipboard=enabled \
        -D xv=enabled \
        -D drm=enabled \
        -D gbm=enabled \
        -D gl=enabled \
        -D plain-gl=enabled \
        -D egl=enabled \
        -D egl-drm=enabled \
        -D egl-wayland=enabled \
        -D egl-x11=enabled \
        -D gl-x11=disabled \
        -D vaapi=enabled \
        -D vaapi-drm=enabled \
        -D vaapi-wayland=enabled \
        -D vaapi-x11=enabled \
        -D vdpau=disabled \
        -D vdpau-gl-x11=disabled \
        -D cuda-hwaccel=disabled \
        -D cuda-interop=disabled \
        -D vulkan=enabled \
        -D shaderc=disabled \
        -D spirv-cross=disabled \
        -D caca=disabled \
        -D sixel=disabled \
        -D manpage-build=enabled \
        -D html-build=disabled \
        -D pdf-build=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
