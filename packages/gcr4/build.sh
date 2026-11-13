build() {
    mkdir build
    cd build
    # - gpg_path: GnuPG does not exist here; without a path meson would stop
    #   looking for gpg2 or gpg. The path is only used at run time, to list
    #   and import PGP keys, and that simply finds nothing until a gpg is
    #   installed there.
    # - ssh_agent: gcr-ssh-agent wraps OpenSSH's ssh-agent and ssh-add, which
    #   must be present at build time; OpenSSH does not exist here. systemd
    #   and libsecret only serve that agent.
    # - crypto: libgcrypt, the book's choice.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D gtk4=true \
        -D introspection=true \
        -D vapi=true \
        -D gtk_doc=false \
        -D gpg_path=/usr/bin/gpg \
        -D crypto=libgcrypt \
        -D ssh_agent=false \
        -D systemd=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
