#!/bin/bash
# End-to-end test of the dave command line against a local signed repository,
# installing into a scratch directory. Needs no privileges and no VM.
set -euo pipefail

top=$(cd "$(dirname "$0")/.." && pwd)
dave=${DAVE:-$top/dave/zig-out/bin/dave}
work=$top/build/cli-test
rm -rf "$work"
mkdir -p "$work"/{repo,root/etc/dave/keys}
cd "$work"

fail() { echo "FAIL: $*" >&2; exit 1; }
expect() { # expect <description> <needle> <<< haystack
    local text; text=$(cat)
    grep -qF -- "$2" <<<"$text" || fail "$1: expected '$2' in: $text"
}

# make_pkg <name> <version> <file> <content> [depends...]
make_pkg() {
    local name=$1 version=$2 file=$3 content=$4; shift 4
    local stage=$work/stage/$name-$version
    mkdir -p "$stage/$(dirname "$file")"
    printf '%s\n' "$content" > "$stage/$file"
    local deps=()
    for d in "$@"; do deps+=(--depends "$d"); done
    "$dave" pack --name "$name" --version "$version" --out "$work/repo" "${deps[@]}" "$stage" >/dev/null
}

"$dave" key generate "$work/signing" >/dev/null
cp "$work/signing.pub" root/etc/dave/keys/
cat > root/etc/dave/repos.zon <<EOF
.{ .repos = .{ .{ .name = "test", .url = "$work/repo" } } }
EOF
D=("$dave" --root "$work/root")

make_pkg libgreet 1.0-r1 usr/lib/libgreet.txt "greet v1"
make_pkg hello 1.0-r1 usr/bin/hello "hello v1" "libgreet >=1.0"
make_pkg tree 2.2-r1 usr/bin/tree "tree"
make_pkg broken 1.0-r1 usr/bin/broken "x" "libgreet >=9"
"$dave" repo index "$work/repo" --key "$work/signing.key" | expect "index" "Indexed 4 package(s)."

echo "== install pulls in dependencies"
"${D[@]}" install hello | expect "plan" "install  libgreet  1.0-r1"
[[ $(cat root/usr/bin/hello) == "hello v1" ]] || fail "hello not installed"
[[ $(cat root/usr/lib/libgreet.txt) == "greet v1" ]] || fail "dependency not installed"
"${D[@]}" list | expect "list" "libgreet 1.0-r1  (dependency)"
"${D[@]}" list | expect "list" "hello 1.0-r1"
[[ $(cat root/etc/dave/world) == "hello" ]] || fail "world not recorded"
"${D[@]}" install hello | expect "idempotent" "Already installed."

echo "== an impossible request is explained and changes nothing"
out=$("${D[@]}" install broken 2>&1) && fail "impossible install succeeded"
expect "explanation" "broken 1.0-r1 depends on libgreet >=9" <<<"$out"
expect "explanation" "you asked for broken" <<<"$out"
[[ ! -e root/usr/bin/broken ]] || fail "broken was installed"
[[ $(cat root/etc/dave/world) == "hello" ]] || fail "world changed by a failed install"
out=$("${D[@]}" install nosuchpackage 2>&1) && fail "missing package install succeeded"
expect "missing" "no package named nosuchpackage exists" <<<"$out"

echo "== upgrade moves to the newest versions"
make_pkg libgreet 1.1-r1 usr/lib/libgreet.txt "greet v1.1"
make_pkg hello 2.0-r1 usr/bin/hello "hello v2" "libgreet >=1.1"
"$dave" repo index "$work/repo" --key "$work/signing.key" >/dev/null
"${D[@]}" install tree | expect "no unrelated upgrades" "install  tree  2.2-r1"
[[ $(cat root/usr/bin/hello) == "hello v1" ]] || fail "install upgraded an unrelated package"
"${D[@]}" upgrade | expect "upgrade" "upgrade  hello  1.0-r1 -> 2.0-r1"
[[ $(cat root/usr/bin/hello) == "hello v2" ]] || fail "hello not upgraded"
[[ $(cat root/usr/lib/libgreet.txt) == "greet v1.1" ]] || fail "libgreet not upgraded"
"${D[@]}" upgrade | expect "up to date" "Everything is up to date."

echo "== remove takes orphaned dependencies along"
out=$("${D[@]}" remove libgreet 2>&1) && fail "removed a dependency directly"
expect "dependency" "another package needs it" <<<"$out"
"${D[@]}" remove hello | expect "orphan" "remove   libgreet  1.1-r1"
[[ ! -e root/usr/bin/hello && ! -e root/usr/lib/libgreet.txt ]] || fail "files left behind"
[[ -e root/usr/bin/tree ]] || fail "unrelated package removed"

echo "== a tampered index is refused"
sed -i 's/tree/trex/' "$work/repo/repo.zon"
out=$("${D[@]}" install hello 2>&1) && fail "accepted a tampered index"
expect "signature" "not signed by a trusted key" <<<"$out"
[[ ! -e root/usr/bin/hello ]] || fail "installed from a tampered index"

echo "== a tampered package is refused"
"$dave" repo index "$work/repo" --key "$work/signing.key" >/dev/null
rm -rf root/var/cache/dave/pkgs
echo garbage > "$work/repo/hello-2.0-r1-x86_64.dave"
out=$("${D[@]}" install hello 2>&1) && fail "accepted a tampered package"
expect "checksum" "does not match the signed index" <<<"$out"
[[ ! -e root/usr/bin/hello ]] || fail "installed a tampered package"

echo "== an unsigned repository fails the seal audit"
out=$("$dave" repo audit "$work/repo" 2>&1) && fail "unsigned repository passed its audit"
expect "audit" "not sealed" <<<"$out"

echo "== undeclared is reserved even without a signing key"
mkdir -p "$work/stage/invalid/usr/bin"
printf 'invalid\n' > "$work/stage/invalid/usr/bin/invalid"
out=$("$dave" pack --name invalid --version 1.0-r1 --allow undeclared --out "$work/repo" "$work/stage/invalid" 2>&1) && \
    fail "accepted an explicit undeclared operation"
expect "reserved undeclared" "InvalidOperation" <<<"$out"

echo "== a failed seal pass leaves no completion marker"
out=$("${D[@]}" seal 2>&1) && fail "sealed a root containing unsigned packages"
expect "strict seal" "missing, malformed, or unreadable seals" <<<"$out"
[[ ! -e root/usr/lib/dave/sealed ]] || fail "failed seal pass wrote its completion marker"

echo "cli tests passed"
