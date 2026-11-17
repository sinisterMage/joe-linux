# Not in the book: the newest upstream release, built with meson as its
# README describes. The release tarball is upstream's "meson dist" with
# the crates vendored (vendor/, .cargo/config); cargo finds that
# configuration from the build directory.
prepare() {
    # --locked: build exactly the crate versions in Cargo.lock. Meson's
    # cargo invocation does not pass it.
    sed -i "s/^cargo_options = \[/&'--locked', /" src/meson.build
    grep -q "'--locked'" src/meson.build
    # The 6.0.2 release's Cargo.lock still gives NewsFlash's own crate as
    # 6.0.1, so --locked refuses it; no dependency's version changes.
    sed -i '/^name = "news_flash_gtk"$/{n;s/^version = "6.0.1"$/version = "6.0.2"/}' Cargo.lock
    grep -A1 '^name = "news_flash_gtk"$' Cargo.lock | grep -x 'version = "6.0.2"' >/dev/null

    # meson.build still requires WebKitGTK, which NewsFlash replaced with
    # its own html2gtk widget; nothing links it (no webkit crate in
    # Cargo.lock) and it does not exist here.
    sed -i "/dependency('webkitgtk-6.0'/d" meson.build
    if grep -q webkitgtk meson.build; then
        return 1
    fi
}

build() {
    # aws-lc-sys looks for an installed AWS-LC before compiling its own;
    # OpenSSL is not one, so say so rather than let it probe.
    export AWS_LC_SYS_USE_SYSTEM=0
    mkdir build
    cd build
    # Upstream's defaults, stated: malloc_trim from glibc, PDF export
    # (Typst, compiled in) and face-aware thumbnails.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=default \
        -D libc=true \
        -D pdf_export=true \
        -D smart_thumbnails=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
