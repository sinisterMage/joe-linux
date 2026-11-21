# pour is Julia, run from source with the medium's Julia. joe-installer.patch
# is what the installer needs and upstream does not have yet (see its
# header); it goes once upstream has it.

prepare() {
    patch -Np1 -i /recipe/joe-installer.patch
}

package() {
    local dest=$DESTDIR/usr/share/pour
    install -d "$dest" "$DESTDIR/usr/bin"
    cp -a Project.toml src LICENSE "$dest/"
    # Julia compiles pour on its first run, into a depot of the caller's own:
    # the medium's root is read-only, and the cache is not worth carrying.
    cat > "$DESTDIR/usr/bin/pour" <<'EOT'
#!/bin/bash
depot=${XDG_CACHE_HOME:-${HOME:-/tmp}/.cache}/pour
[[ -w ${depot%/*} || -w ${depot%/*/*} ]] || depot=$(mktemp -d /tmp/pour.XXXXXX)
mkdir -p "$depot"
export JULIA_DEPOT_PATH="$depot:"
exec /usr/bin/julia --startup-file=no --history-file=no --project=/usr/share/pour \
    -e 'using Pour; exit(Pour.main(ARGS))' -- "$@"
EOT
    chmod 755 "$DESTDIR/usr/bin/pour"
}
