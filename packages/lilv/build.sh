# Not in the book: the newest upstream release, built with meson as its
# INSTALL.md says. The default plugin path is upstream's for Linux
# (~/.lv2:/usr/local/lib/lv2:/usr/lib/lv2). Left out: the Python bindings
# (a ctypes module nothing in joe uses), dynamic manifests (an unfinished
# LV2 extension upstream also leaves off), and the reference documentation
# (doxygen, sphinx and sphinxygen, which meson would try to fetch).
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --sysconfdir=/etc \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D tools=enabled \
        -D bindings_py=disabled \
        -D dynmanifest=disabled \
        -D docs=disabled \
        -D html=disabled \
        -D singlehtml=disabled \
        -D tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
    # Upstream puts the completion (for lv2info only) in
    # /etc/bash_completion.d; bash-completion loads it on demand from here.
    install -d "$DESTDIR/usr/share/bash-completion/completions"
    mv "$DESTDIR/etc/bash_completion.d/lilv" "$DESTDIR/usr/share/bash-completion/completions/lv2info"
    rmdir "$DESTDIR/etc/bash_completion.d" "$DESTDIR/etc"
}
