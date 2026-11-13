build() {
    mkdir bld
    cd bld
    # No tpm2-tss and no bash-completion in joe Linux; the PAM module is off
    # as in the book.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gtk_doc=false \
        -D manpage=true \
        -D crypto=libgcrypt \
        -D introspection=true \
        -D vapi=true \
        -D tpm2=false \
        -D pam=false \
        -D bash_completion=disabled \
        -D test_setup=disabled
    ninja
}

package() {
    cd bld
    DESTDIR="$DESTDIR" ninja install
}
