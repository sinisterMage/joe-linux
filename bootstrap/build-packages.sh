#!/bin/bash
# Builds every recipe in packages/ORDER with `dave build`, publishing the
# packages to build/repo and installing each one into the build root so the
# next recipe builds against it. This is where the temporary tools of stages 1
# and 2 are replaced, one by one, by real joe Linux packages.
#
#   build-packages.sh [PACKAGE...]    build only the named packages (in order)
#
# Resumable: a package whose file already exists in the repository is skipped.
set -euo pipefail

top=$(cd "$(dirname "$0")/.." && pwd)
root=$top/build/bootstrap/root
repo=$top/build/repo
keys=$top/build/keys
dave=$top/dave/zig-out/bin/dave

if [[ $(id -u) -ne 0 ]]; then
    [[ -e $top/build/bootstrap/done/cleanup ]] || { echo "run stage1.sh and stage2.sh first" >&2; exit 1; }
    (cd "$top/dave" && zig build -Doptimize=ReleaseSafe)
    mkdir -p "$keys" "$repo"
    [[ -e $keys/joe.key ]] || "$dave" key generate "$keys/joe" >/dev/null
    # The dave recipe packages the binary just built and the units in system/.
    mkdir -p "$top/packages/dave/files"
    cp "$dave" "$top"/system/* "$top/packages/dave/files/"
    # Installing into the build root runs triggers in a chroot, which needs the
    # privileges a user namespace provides.
    exec unshare --map-root-user "$0" "$@"
fi

# The build root is itself managed by dave, using the repository being built.
mkdir -p "$root/etc/dave/keys"
cp "$keys/joe.pub" "$root/etc/dave/keys/"
cat > "$root/etc/dave/repos.zon" <<EOT
.{ .repos = .{ .{ .name = "joe", .url = "$repo" } } }
EOT

field() { # field <recipe dir> <name>: a top-level value from package.zon
    sed -n "s/^ *\.$2 = \"\{0,1\}\([^\",]*\)\"\{0,1\},.*/\1/p" "$1/package.zon" | head -n 1
}

wanted=("$@")
while read -r name flag; do
    [[ -z $name || $name == \#* ]] && continue
    if [[ ${#wanted[@]} -gt 0 ]] && [[ ! " ${wanted[*]} " == *" $name "* ]]; then continue; fi
    recipe=$top/packages/$name
    [[ -e $recipe/package.zon ]] || { echo "no recipe for $name" >&2; exit 1; }
    version=$(field "$recipe" version)-r$(field "$recipe" release)
    file=$repo/$name-$version-x86_64.dave

    if [[ ! -e $file ]]; then
        echo "==> building $name $version"
        started=$SECONDS
        if ! "$dave" build "$recipe" --buildroot "$root" --sources "$top/build/src" \
            --work "$top/build/work" --out "$repo" >/dev/null; then
            echo "--- last lines of $top/build/work/$name/build.log" >&2
            tail -n 40 "$top/build/work/$name/build.log" >&2 || true
            exit 1
        fi
        echo "    built in $((SECONDS - started))s, $(du -h "$file" | cut -f1)"
        "$dave" repo index "$repo" --key "$keys/joe.key" >/dev/null
    fi

    [[ $flag == build-only ]] && continue
    if ! "$dave" --root "$root" list | grep -qx "$name $version\( .*\)\{0,1\}"; then
        echo "    installing $name $version into the build root"
        "$dave" --root "$root" --overwrite install "$name=$version" >/dev/null
    fi
done < "$top/packages/ORDER"

echo "all packages built: $repo"
