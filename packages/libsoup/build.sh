build() {
    mkdir build
    cd build
    # GSSAPI (krb5) and NTLM through Samba's ntlm_auth are left out, as are
    # sysprof and the API documentation. tls_check=false: do not try to load
    # a GIO TLS backend while configuring; glib-networking is a run-time
    # dependency.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D introspection=enabled \
        -D vapi=enabled \
        -D brotli=enabled \
        -D zstd=enabled \
        -D gssapi=disabled \
        -D ntlm=disabled \
        -D sysprof=disabled \
        -D docs=disabled \
        -D tls_check=false \
        -D tests=false \
        -D installed_tests=false \
        -D autobahn=disabled \
        -D pkcs11_tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
