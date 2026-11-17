# Not in the book: the newest upstream release, built with its own build
# script (hack/make-rules/build.sh, what "make WHAT=cmd/kubeadm" runs) from
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
    hack/make-rules/build.sh cmd/kubeadm

    local kubeadm=_output/local/bin/linux/amd64/kubeadm
    "$kubeadm" completion bash > kubeadm.bash
    "$kubeadm" completion zsh > _kubeadm
}

package() {
    install -Dm755 _output/local/bin/linux/amd64/kubeadm "$DESTDIR/usr/bin/kubeadm"
    install -Dm644 kubeadm.bash "$DESTDIR/usr/share/bash-completion/completions/kubeadm"
    install -Dm644 _kubeadm "$DESTDIR/usr/share/zsh/site-functions/_kubeadm"

    # The kubelet drop-in upstream's kubeadm package ships (kubernetes/release,
    # cmd/krel/templates/latest/kubeadm/10-kubeadm.conf): kubelet's
    # arguments come from the files kubeadm init and kubeadm join write.
    install -d "$DESTDIR/usr/lib/systemd/system/kubelet.service.d"
    cat > "$DESTDIR/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf" << "EOF2"
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/sysconfig/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
EOF2
}
