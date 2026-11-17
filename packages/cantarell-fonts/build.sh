# Not in the book: the newest upstream release, built with meson as its
# README says from the prebuilt fonts in the tarball (building them from
# source needs fontmake and otfautohint). It installs what upstream
# installs by default: the variable font, which covers every weight, and
# the AppStream metadata. fontconfig's trigger rebuilds the cache.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D useprebuilt=true \
        -D buildvf=true \
        -D buildstatics=false \
        -D buildappstream=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
