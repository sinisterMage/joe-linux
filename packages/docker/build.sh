# Not in the book: the newest upstream release. The engine is built with
# hack/make.sh dynbinary, as the docker-ce packages are (dynamically linked,
# with the journald log reader), the CLI with scripts/build/binary
# (GO_LINKMODE=dynamic), and docker-init from tini as the engine's
# Dockerfile builds it. 06db173 and fdd4b8e are the commits the
# docker-v29.10.0 and v29.10.0 tags point to, which the scripts would take
# from git. Left out: the rootless helpers (contrib/dockerd-rootless*.sh),
# and buildx, the plugin docker build prefers (not packaged; docker build
# then uses the classic builder).
prepare() {
    mkdir cli tini
    tar -xf "$SOURCES/docker-cli-29.10.0.tar.gz" -C cli --strip-components=1
    tar -xf "$SOURCES/tini-0.19.0.tar.gz" -C tini --strip-components=1
    # tini builds with -Werror -pedantic-errors; a warning new in this
    # compiler must not stop the build.
    sed -i 's/ -Werror//' tini/CMakeLists.txt
}

go_env() {
    # Go's caches in the build directory, outside the source trees; never
    # fetch another Go toolchain.
    export GOPATH=/build/go
    export GOCACHE=/build/go/cache
    export GOTOOLCHAIN=local GOTELEMETRY=off
    # Both build scripts add -buildmode=pie themselves.
    export GOFLAGS="-mod=vendor -trimpath"
}

build() {
    go_env

    # The engine: dockerd and docker-proxy, in bundles/dynbinary-daemon.
    # journald is the tag the script adds itself when libsystemd is there;
    # it is given explicitly. The nftables firewall back end runs nft (the
    # libnftables tag, linking it instead, is off, as upstream builds).
    VERSION="$PKG_VERSION" DOCKER_GITCOMMIT=06db173 \
        DOCKER_BUILDTAGS=journald EXCLUDE_AUTO_BUILDTAG_JOURNALD=1 \
        hack/make.sh dynbinary
    make -C man GO_MD2MAN=go-md2man

    # The CLI. It has a vendor.mod rather than a go.mod; with-go-mod.sh
    # makes it a module for the duration of the command.
    (
        cd cli
        VERSION="$PKG_VERSION" GITCOMMIT=fdd4b8e GO_LINKMODE=dynamic \
            scripts/with-go-mod.sh scripts/build/binary
        GO_MD2MAN=go-md2man scripts/with-go-mod.sh scripts/docs/generate-man.sh
    )

    # docker-init: tini, statically linked.
    cmake -S tini -B tini/build -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    make -C tini/build tini-static
}

package() {
    install -Dm755 bundles/dynbinary-daemon/dockerd "$DESTDIR/usr/bin/dockerd"
    install -Dm755 bundles/dynbinary-daemon/docker-proxy "$DESTDIR/usr/bin/docker-proxy"
    install -Dm755 cli/build/docker "$DESTDIR/usr/bin/docker"
    install -Dm755 tini/build/tini-static "$DESTDIR/usr/bin/docker-init"

    make -C man prefix=/usr mandir=/usr/share/man GO_MD2MAN=go-md2man DESTDIR="$DESTDIR" install
    local sec
    for sec in 1 5 8; do
        if [[ -d cli/man/man$sec ]]; then
            install -d "$DESTDIR/usr/share/man/man$sec"
            install -m644 cli/man/man$sec/* "$DESTDIR/usr/share/man/man$sec/"
        fi
    done

    install -Dm644 cli/contrib/completion/bash/docker "$DESTDIR/usr/share/bash-completion/completions/docker"
    install -Dm644 cli/contrib/completion/zsh/_docker "$DESTDIR/usr/share/zsh/site-functions/_docker"
    install -Dm644 cli/contrib/completion/fish/docker.fish "$DESTDIR/usr/share/fish/vendor_completions.d/docker.fish"

    # Upstream's unit and socket. Neither is enabled. docker.service uses
    # the separate containerd.service (--containerd=...), which it wants.
    install -d "$DESTDIR/usr/lib/systemd/system"
    install -m644 contrib/init/systemd/docker.service contrib/init/systemd/docker.socket \
        "$DESTDIR/usr/lib/systemd/system/"

    # The docker group owns the API socket. Membership in it is equivalent
    # to root (contrib/systemd-sysusers/docker.conf says so); its id is
    # fixed, as every group's is here.
    install -d "$DESTDIR/usr/lib/sysusers.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/docker.conf" << "EOF2"
g docker 59
EOF2
}
