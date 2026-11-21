# The second recipe that packages an upstream binary instead of building from
# source (bun is the first), by decision: Julia builds its own fork of LLVM
# and a dozen libraries, and it is needed only to run pour from the
# installation medium, whose security module only logs. A just-in-time
# compiler cannot run privileged on a system that enforces (rule 2), so it is
# not part of what is installed.

# Already stripped by upstream; its system image must not be touched.
NOSTRIP=1

package() {
    local dest=$DESTDIR/usr/lib/julia
    install -d "$dest" "$DESTDIR/usr/bin"
    cp -a bin etc lib libexec share LICENSE.md "$dest/"
    # The precompiled standard libraries are 370 MB; pour loads one (SHA).
    # Julia compiles any other it is asked for, into the user's depot.
    local cache
    for cache in "$dest"/share/julia/compiled/*/*; do
        [[ $(basename "$cache") == SHA ]] || rm -rf "$cache"
    done
    rm -rf "$dest/share/julia/test" "$dest/share/doc" "$dest/share/man"
    ln -s ../lib/julia/bin/julia "$DESTDIR/usr/bin/julia"
}
