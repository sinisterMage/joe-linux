# Not in the book. The configuration files and manual pages shared by
# Podman, Buildah and Skopeo, laid out as other distributions do: the
# defaults in /usr/share/containers, where the libraries look after
# /etc/containers, which is left to the administrator (a file there
# replaces the default; a .d directory there adds to it).
#
# containers.conf, seccomp.json and the hooks and Containerfile manuals come
# from common (the first archive), registries.conf, policy.json and
# registries.d from image, storage.conf from storage. containers.conf is
# upstream's, every option commented out, so the built-in defaults apply:
# the runtime is crun if installed and otherwise runc, the network stack
# netavark with its nftables driver, rootless networking pasta, logs and
# events go to journald.
prepare() {
    mkdir image-lib storage-lib shortnames
    # Only the library's own directory of each of the other two archives.
    tar -xf "$SOURCES/container-libs-image-5.42.1.tar.gz" -C image-lib \
        --strip-components=2 container-libs-image-v5.42.1/image
    tar -xf "$SOURCES/container-libs-storage-1.65.1.tar.gz" -C storage-lib \
        --strip-components=2 container-libs-storage-v1.65.1/storage
    tar -xf "$SOURCES/shortnames-2025.03.19.tar.gz" -C shortnames --strip-components=1
}

build() {
    make -C common/docs GOMD2MAN=go-md2man
    cc -O2 -Wall -Wextra -o joe-setup-subids /recipe/joe-subids.c -lsubid
    go-md2man -in common/pkg/hooks/docs/oci-hooks.5.md -out oci-hooks.5
    local md
    for md in image-lib/docs/*.5.md; do
        go-md2man -in "$md" -out "${md%.md}"
    done
    go-md2man -in storage-lib/docs/containers-storage.conf.5.md -out containers-storage.conf.5
}

package() {
    install -Dm755 joe-setup-subids "$DESTDIR/usr/libexec/joe-setup-subids"
    install -Dm644 /recipe/14-subids.zon "$DESTDIR/usr/lib/dave/triggers/14-subids.zon"

    local share="$DESTDIR/usr/share/containers"
    install -Dm644 common/pkg/config/containers.conf "$share/containers.conf"
    install -Dm644 common/pkg/seccomp/seccomp.json "$share/seccomp.json"
    install -Dm644 image-lib/registries.conf "$share/registries.conf"
    install -Dm644 image-lib/default-policy.json "$share/policy.json"
    install -Dm644 image-lib/default.yaml "$share/registries.d/default.yaml"
    install -Dm644 storage-lib/storage.conf "$share/storage.conf"
    install -Dm644 shortnames/shortnames.conf "$share/registries.conf.d/00-shortnames.conf"

    # The manual pages of the files above.
    make -C common/docs PREFIX=/usr DESTDIR="$DESTDIR" install
    install -m644 oci-hooks.5 containers-storage.conf.5 image-lib/docs/*.5 "$DESTDIR/usr/share/man/man5/"

    # Rootful storage, and the signature store registries.d/default.yaml
    # names, are in /var, which is not packaged.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/containers-common.conf" << "EOF2"
d /var/lib/containers 0755 root root -
d /var/lib/containers/sigstore 0755 root root -
EOF2
}
