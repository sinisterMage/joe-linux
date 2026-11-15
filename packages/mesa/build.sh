build() {
    mkdir -p build
    cd build
    # Drivers for real graphics hardware and for virtual machines:
    # - iris and crocus (Intel, from 2008 on), radeonsi (AMD, from 2012 on)
    #   and nouveau (NVIDIA);
    # - llvmpipe and softpipe (no GPU, or none the others drive), virgl
    #   (virtio-gpu) and svga (VMware).
    # Intel's drivers compile their own compute kernels while Mesa builds,
    # which takes clang (part of llvm), SPIRV-LLVM-Translator and
    # SPIRV-Tools; radeonsi needs LLVM's AMDGPU target, which llvm builds.
    #
    # No Vulkan drivers yet (they need glslang and the Vulkan loader).
    #
    # VA-API (gallium-va, through libva) gives hardware video decoding and
    # encoding to Firefox, GStreamer and ffmpeg on radeonsi, nouveau and virgl.
    # Every codec Mesa has is built, H.264, H.265 and VC-1 included, as joe
    # already ships decoders and encoders for them (gst-libav, x264, x265).
    #
    # Switched off because what they need is not part of joe Linux: glvnd
    # (libglvnd), lmsensors. valgrind and libunwind only help to debug Mesa
    # itself. display-info
    # (libdisplay-info) and xlib-lease (libXrandr) are only used by the Vulkan
    # window-system code.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D platforms=x11,wayland \
        -D gallium-drivers=iris,crocus,radeonsi,nouveau,llvmpipe,softpipe,virgl,svga \
        -D "vulkan-drivers=[]" \
        -D video-codecs=all \
        -D glx=dri \
        -D egl=enabled \
        -D gbm=enabled \
        -D gles2=enabled \
        -D llvm=enabled \
        -D shared-llvm=enabled \
        -D zstd=enabled \
        -D expat=enabled \
        -D valgrind=disabled \
        -D libunwind=disabled \
        -D gallium-va=enabled \
        -D glvnd=disabled \
        -D lmsensors=disabled \
        -D display-info=disabled \
        -D spirv-tools=enabled \
        -D xlib-lease=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
