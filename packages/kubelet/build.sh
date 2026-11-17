# Not in the book: the newest upstream release, built with its own build
# script (hack/make-rules/build.sh, what "make WHAT=cmd/kubelet" runs) from
# the release's source tarball, offline from the vendored modules. The
# version stamps come from the tarball itself (hack/lib/version.sh is
# filled in by git archive). Manual pages: see the kubectl recipe.
unpack() {
    # The tarball has no top-level directory.
    tar -xf "$SOURCES/$PKG_SOURCE" --no-same-owner --no-same-permissions
}

build() {
    # FORCE_HOST_GO: build with this Go instead of downloading the version
    # in .go-version. Caches go to _output/local/go in the source tree.
    export FORCE_HOST_GO=1 GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=vendor -buildmode=pie"
    export KUBE_BUILD_PLATFORMS=linux/amd64
    hack/make-rules/build.sh cmd/kubelet
}

package() {
    install -Dm755 _output/local/bin/linux/amd64/kubelet "$DESTDIR/usr/bin/kubelet"

    # The unit upstream's packages ship (kubernetes/release,
    # cmd/krel/templates/latest/kubelet/kubelet.service). Not enabled.
    # kubeadm adds the drop-in that gives it its arguments.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/kubelet.service" << "EOF2"
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF2

    # The directories upstream's packages own: kubelet's state, and the
    # static pod manifests kubeadm writes.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/kubelet.conf" << "EOF2"
d /var/lib/kubelet 0755 root root -
d /etc/kubernetes/manifests 0755 root root -
EOF2
}
