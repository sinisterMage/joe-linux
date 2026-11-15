# Not in the book: upstream's source release, built with make.bash as
# https://go.dev/doc/install/source describes, and installed where Arch and
# Fedora put it (/usr/lib/go, with go and gofmt linked into /usr/bin). The go
# command finds its GOROOT from its own location.
#
# go.env keeps upstream's defaults: the module proxy, the checksum database,
# and GOTOOLCHAIN=auto. Recipes that build Go programs set GOTOOLCHAIN=local
# so that they are built with this Go.

# The source tree carries ELF test data (debug/elf, cmd/link) that stripping
# would change, and the tools are already as small as Go makes them.
NOSTRIP=1

_go_env() {
    # Keep Go's caches inside the build directory, out of the shared build
    # root's /root.
    export GOCACHE="$PWD/.gocache" GOPATH="$PWD/.gopath"
    export GOTOOLCHAIN=local GOTELEMETRY=off
}

prepare() {
    mkdir .stage0
    tar -xf "$SOURCES/go1.26.11.linux-amd64.tar.gz" -C .stage0 --strip-components=1 \
        --no-same-owner --no-same-permissions
}

build() {
    _go_env
    cd src
    GOROOT_BOOTSTRAP="$PWD/../.stage0" bash make.bash -v=1
}

package() {
    local goroot="$DESTDIR/usr/lib/go"
    install -d "$goroot" "$DESTDIR/usr/bin"
    cp -a api bin lib misc pkg src "$goroot/"
    install -m644 VERSION go.env LICENSE PATENTS "$goroot/"
    # Left over from building: the bootstrap's intermediate objects.
    rm -rf "$goroot/pkg/obj" "$goroot/pkg/bootstrap"
    ln -s ../lib/go/bin/go "$DESTDIR/usr/bin/go"
    ln -s ../lib/go/bin/gofmt "$DESTDIR/usr/bin/gofmt"
}
