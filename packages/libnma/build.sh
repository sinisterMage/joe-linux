build() {
    mkdir build
    cd build
    # The mobile broadband wizard offers the providers in
    # mobile-broadband-provider-info.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D libnma_gtk4=true \
        -D gcr=true \
        -D iso_codes=true \
        -D mobile_broadband_provider_info=true \
        -D introspection=true \
        -D vapi=true \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
