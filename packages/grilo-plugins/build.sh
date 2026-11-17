# Not in the book: the newest upstream release, built with meson as its
# README says. Every plugin is chosen explicitly. Left out:
# - bookmarks and thetvdb: they need gom, which joe does not package;
# - dmap (DAAP/DPAP shares): libdmapsharing has no recipe;
# - flickr: liboauth has no recipe;
# - youtube: needs libgdata, which has no libsoup 3 version;
# - dleyna: talks to dleyna-server, which joe does not package;
# - tracker: the old Tracker 2 plugin (tracker3 is built).
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D enable-bookmarks=no \
        -D enable-chromaprint=yes \
        -D enable-dleyna=no \
        -D enable-dmap=no \
        -D enable-filesystem=yes \
        -D enable-flickr=no \
        -D enable-freebox=yes \
        -D enable-gravatar=yes \
        -D enable-local-metadata=yes \
        -D enable-lua-factory=yes \
        -D enable-magnatune=yes \
        -D enable-metadata-store=yes \
        -D enable-optical-media=yes \
        -D enable-podcasts=yes \
        -D enable-shoutcast=yes \
        -D enable-thetvdb=no \
        -D enable-tmdb=yes \
        -D enable-tracker=no \
        -D enable-tracker3=yes \
        -D enable-youtube=no \
        -D goa=enabled \
        -D help=yes
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
