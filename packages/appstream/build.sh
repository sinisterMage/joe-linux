unpack() {
    # Every path in this tarball starts with "./", which tar counts as a
    # component of its own.
    tar -xf "$SOURCES/$PKG_SOURCE" --strip-components=2 --no-same-owner --no-same-permissions
}

build() {
    mkdir build
    cd build
    # The manual pages need the namespaced DocBook stylesheets
    # (docbook-xsl-ns), which have no recipe; neither have libstemmer,
    # gi-docgen and bash-completion. install-docs would only put ready-made
    # HTML into usr/share/doc.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D apidocs=false \
        -D docs=false \
        -D install-docs=false \
        -D man=false \
        -D bash-completion=false \
        -D stemming=false \
        -D systemd=true \
        -D zstd-support=true \
        -D display-detection=wayland \
        -D gir=true \
        -D vapi=false \
        -D qt=false \
        -D compose=false \
        -D apt-support=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # The book also writes /usr/share/metainfo/org.linuxfromscratch.lfs.xml,
    # an operating-system component describing Linux From Scratch. The one
    # describing joe Linux belongs with os-release in joe-release.
}
