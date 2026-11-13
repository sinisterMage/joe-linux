build() {
    mkdir -p build
    cd build
    # Drivers for virtual machines and for no hardware at all, which need nothing
    # beyond LLVM: llvmpipe and softpipe (software), virgl (virtio-gpu) and svga
    # (VMware). The book's "auto" would add the hardware drivers, and with them
    # glslang, SPIRV-LLVM-Translator, libclc, rust-bindgen and the Vulkan loader.
    #
    # No Vulkan drivers (they need glslang) and so no video codecs, which only
    # the Vulkan and VA-API front ends use.
    #
    # Switched off because what they need is not part of joe Linux: gallium-va
    # (libva), glvnd (libglvnd), lmsensors, spirv-tools, valgrind, libunwind.
    # display-info (libdisplay-info) and xlib-lease (libXrandr) are only used by
    # the Vulkan window-system code.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D platforms=x11,wayland \
        -D gallium-drivers=llvmpipe,softpipe,virgl,svga \
        -D "vulkan-drivers=[]" \
        -D "video-codecs=[]" \
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
        -D gallium-va=disabled \
        -D glvnd=disabled \
        -D lmsensors=disabled \
        -D display-info=disabled \
        -D spirv-tools=disabled \
        -D xlib-lease=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
