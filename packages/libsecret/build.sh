build() {
    mkdir bld
    cd bld
    # TPM-backed secrets and shell completion are available; the PAM module
    # remains off as in the book.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gtk_doc=false \
        -D manpage=true \
        -D crypto=libgcrypt \
        -D introspection=true \
        -D vapi=true \
        -D tpm2=true \
        -D pam=false \
        -D bash_completion=enabled \
        -D test_setup=disabled
    ninja
}

package() {
    cd bld
    DESTDIR="$DESTDIR" ninja install
}
