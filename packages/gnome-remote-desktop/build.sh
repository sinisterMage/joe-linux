# Not in the book: the newest upstream release, built with meson as its
# README says.
build() {
    mkdir build
    cd build
    # Only the VNC backend. The RDP backend, which is upstream's default
    # and what GNOME Settings' Remote Desktop and Remote Login pages use,
    # requires the Vulkan headers and loader, glslc (shaderc) and
    # spirv-opt to compile its shaders, fdk-aac for audio and the
    # ffnvcodec headers, and the first three and fdk-aac have no recipes.
    # It also brings the system daemon, its account, polkit rules and the
    # system units. With VNC alone, sharing is set up with grdctl and runs
    # in the user's session.
    # The manual page needs a2x (AsciiDoc), which has no recipe; the tests
    # need a nested Mutter.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D rdp=false \
        -D vnc=true \
        -D systemd=true \
        -D man=false \
        -D tests=false
    ninja
}

package() {
    cd build
    # Installs the user units gnome-remote-desktop.service and
    # gnome-remote-desktop-headless.service; neither is enabled.
    DESTDIR="$DESTDIR" ninja install
}
