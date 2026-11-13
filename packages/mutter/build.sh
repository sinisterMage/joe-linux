build() {
    mkdir build
    cd build
    # The book's options (tests, profiler, bash_completion off) with every
    # other choice stated:
    # - Wayland compositor on KMS/libinput (always built in this version),
    #   with Xwayland for X applications; there is no X11 session.
    # - remote_desktop: screen cast and remote desktop through pipewire and
    #   libei.
    # - profiler needs sysprof, docs gi-docgen, the test suites GTK 3,
    #   python-dbusmock and umockdev: none exist here.
    # - devkit (a nested development shell needing libadwaita) is not wanted.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D tests=disabled \
        -D installed_tests=false \
        -D profiler=false \
        -D bash_completion=false \
        -D docs=false \
        -D devkit=disabled \
        -D opengl=true \
        -D egl=true \
        -D gles2=true \
        -D xwayland=true \
        -D xwayland_path=/usr/bin/Xwayland \
        -D xwayland_initfd=enabled \
        -D remote_desktop=true \
        -D libgnome_desktop=true \
        -D libwacom=true \
        -D sound_player=true \
        -D startup_notification=true \
        -D introspection=true \
        -D fonts=true \
        -D udev_dir=/usr/lib/udev
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
