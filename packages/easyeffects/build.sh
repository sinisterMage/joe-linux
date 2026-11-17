# Not in the book: the newest release of the 7.x line, built with meson as
# its README says. EasyEffects 8 is a rewrite on Qt and KDE Frameworks
# (Kirigami, KirigamiAddons, KF6 Config and others), which joe does not
# package, so this is the last release of the GTK 4 and libadwaita line
# (7.2.5, July 2025).
#
# libportal is only used to manage the autostart file from inside Flatpak
# (upstream's default is off); outside it EasyEffects writes the file
# itself. RNNoise noise reduction is built.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D devel=false \
        -D enable-mold=false \
        -D enable-libportal=false \
        -D enable-rnnoise=true \
        -D enable-libcpp-workarounds=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
