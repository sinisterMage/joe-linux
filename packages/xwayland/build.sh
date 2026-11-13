build() {
    mkdir -p build
    cd build
    # xkb_output_dir: where the server writes the keymaps xkbcomp compiles for it.
    #
    # glamor (OpenGL acceleration) uses libepoxy, libdrm and Mesa's GBM; glx
    # needs Mesa's gl.pc and dri.pc; dri3 needs libxshmfence. secure-rpc uses
    # libtirpc. SHA-1 comes from nettle: left alone, the build takes the first
    # of nettle, libgcrypt and OpenSSL it finds. xwayland_ei=portal makes libei
    # and liboeffis required (XTEST emulation through the RemoteDesktop portal).
    #
    # Not built: Xvfb, which the book installs only for the test suite. Not
    # part of joe Linux: libdecor, SELinux, and xmlto for the documentation.
    # The location of the keyboard database and of xkbcomp is read from
    # xkbcomp.pc, the font directory from font-util's fontutil.pc.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D xkb_output_dir=/var/lib/xkb \
        -D glamor=true \
        -D glx=true \
        -D dri3=true \
        -D secure-rpc=true \
        -D sha1=libnettle \
        -D xwayland_ei=portal \
        -D xvfb=false \
        -D libdecor=false \
        -D xselinux=false \
        -D docs=false \
        -D devel-docs=false \
        -D docs-pdf=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # /var is not packaged: the directory for compiled keymaps is made at boot.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/joe-xwayland.conf" <<'EOT'
d /var/lib/xkb 0755 root root -
EOT
}
