build() {
    mkdir build
    cd build
    # The demo needs libadwaita and gtksourceview; gi-docgen does not exist.
    # Certificates come from the system store (make-ca) through GIO.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D soup2=false \
        -D introspection=true \
        -D vapi=false \
        -D ca_certificates=false \
        -D examples=false \
        -D gtk_doc=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
