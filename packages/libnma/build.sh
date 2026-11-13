build() {
    mkdir build
    cd build
    # mobile_broadband_provider_info: the provider database does not exist
    # here, so the mobile broadband wizard has no providers to offer.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D libnma_gtk4=true \
        -D gcr=true \
        -D iso_codes=true \
        -D mobile_broadband_provider_info=false \
        -D introspection=true \
        -D vapi=true \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
