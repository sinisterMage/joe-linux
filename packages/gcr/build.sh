prepare() {
    # As in the book: without OpenSSH the lookups of ssh-add and ssh-agent
    # fail even though the agent is switched off below.
    sed '/ssh.add/d; /ssh.agent/d' -i meson.build
    # A deprecated path in the schema template.
    sed -i 's:"/desktop:"/org:' schema/*.xml
}

build() {
    mkdir build
    cd build
    # - gpg_path: GnuPG does not exist here; without a path meson would stop
    #   looking for gpg2 or gpg. The path is only used at run time, to list
    #   and import PGP keys, and that simply finds nothing until a gpg is
    #   installed there.
    # - ssh_agent: as in the book (the one from gcr4 is the complete one, and
    #   both need OpenSSH at build time). systemd only serves that agent.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D gtk=true \
        -D introspection=true \
        -D gtk_doc=false \
        -D gpg_path=/usr/bin/gpg \
        -D ssh_agent=false \
        -D systemd=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # meson_post_install.py makes libgcr-3.so* point at libgcr-ui-3.so*, but
    # returns early when DESTDIR is set (it also refreshes caches). These are
    # the links it would have made.
    ln -sfv libgcr-ui-3.so "$DESTDIR/usr/lib/libgcr-3.so"
    ln -sfv libgcr-ui-3.so.1 "$DESTDIR/usr/lib/libgcr-3.so.1"
    ln -sfv libgcr-ui-3.so.1.0.0 "$DESTDIR/usr/lib/libgcr-3.so.1.0.0"
}
