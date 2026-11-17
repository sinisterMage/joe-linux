# Following the book's libplacebo page, without its tests. The GitHub
# archive has none of the git submodules in 3rdparty/; the system's glad2,
# jinja2 and fast_float take their place (meson.build looks for them on the
# system first).
#
# OpenGL and Vulkan are enabled. Shaderc is the preferred SPIR-V compiler;
# the redundant glslang backend stays disabled. Direct3D is not a Linux API.
# Dolby Vision metadata is handled by libplacebo's own code; libdovi
# (dovi_tool) has no recipe.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D opengl=enabled \
        -D gl-proc-addr=enabled \
        -D vulkan=enabled \
        -D vk-proc-addr=enabled \
        -D glslang=disabled \
        -D shaderc=enabled \
        -D d3d11=disabled \
        -D lcms=enabled \
        -D dovi=enabled \
        -D libdovi=disabled \
        -D unwind=enabled \
        -D xxhash=enabled \
        -D demos=false \
        -D tests=false \
        -D bench=false \
        -D fuzz=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
