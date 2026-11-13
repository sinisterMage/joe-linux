# Files (nautilus) will not start without this package's settings schema, and
# uses its index for search.
build() {
    mkdir build
    cd build
    # bash_completion stays on with an explicit directory: turned off, this
    # version's meson.build refers to a variable it never set.
    # Extractors are on where the library they need has a recipe, and off by
    # name otherwise, so the result does not depend on the build root.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        --libdir=lib \
        -D man=false \
        -D functional_tests=false \
        -D sandbox_tests=false \
        -D bash_completion=true \
        -D bash_completion_dir=/usr/share/bash-completion/completions \
        -D seccomp=true \
        -D landlock=disabled \
        -D fanotify=enabled \
        -D battery_detection=upower \
        -D charset_detection=icu \
        -D gif=enabled \
        -D jpeg=enabled \
        -D png=enabled \
        -D tiff=enabled \
        -D xml=enabled \
        -D raw=enabled \
        -D cue=disabled \
        -D exif=disabled \
        -D gsf=disabled \
        -D iptc=disabled \
        -D iso=disabled \
        -D pdf=disabled \
        -D playlist=disabled \
        -D xmp=disabled \
        -D xps=disabled \
        -D libav=disabled \
        -D libmediainfo=disabled \
        -D webp=disabled \
        -D zip=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
