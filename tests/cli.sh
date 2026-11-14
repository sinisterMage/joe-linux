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

echo "== repositories over http and https"
for tool in openssl python3 bwrap; do
    command -v "$tool" >/dev/null || fail "the network tests need $tool"
done
# A throwaway certificate authority, a server certificate for 127.0.0.1 and
# one for some other name. dave trusts only the system's certificate store, so
# the test authority is laid over /etc/ssl for one dave process at a time.
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 2 \
    -subj "/CN=dave test authority" -addext basicConstraints=critical,CA:TRUE \
    -addext keyUsage=critical,keyCertSign -keyout ca.key -out ca.pem 2>/dev/null
for site in here:IP:127.0.0.1 elsewhere:DNS:elsewhere.example; do
    name=${site%%:*}
    openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=$name" \
        -keyout "$name.key" -out "$name.csr" 2>/dev/null
    openssl x509 -req -in "$name.csr" -CA ca.pem -CAkey ca.key -CAcreateserial -days 2 \
        -extfile <(printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\n' "${site#*:}") \
        -out "$name.pem" 2>/dev/null
done
mkdir -p "$work/bin"
cat > "$work/bin/serve.py" <<'EOF'
# serve.py DIR CERT...: serves DIR over HTTP, and over HTTPS once per
# certificate (CERT.pem, CERT.key); prints the ports in that order.
import functools, http.server, ssl, sys, threading
directory, *certs = sys.argv[1:]
class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args): pass
ports = []
for cert in [None, *certs]:
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=directory))
    if cert:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(cert + ".pem", cert + ".key")
        server.socket = context.wrap_socket(server.socket, server_side=True)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    ports.append(str(server.server_address[1]))
print(*ports, flush=True)
threading.Event().wait()
EOF
python3 -I "$work/bin/serve.py" "$work/repo" "$work/here" "$work/elsewhere" > ports 2> server.log &
server=$!
trap 'kill $server 2>/dev/null || true' EXIT
for _ in $(seq 100); do [[ -s ports ]] && break; sleep 0.1; done
read -r http_port here_port elsewhere_port < ports || fail "the test server did not start: $(cat server.log)"

net_root() { # net_root DIR URL: an empty root whose only repository is URL
    mkdir -p "$1/etc/dave/keys"
    cp "$work/signing.pub" "$1/etc/dave/keys/"
    printf '.{ .repos = .{ .{ .name = "test", .url = "%s" } } }\n' "$2" > "$1/etc/dave/repos.zon"
}
trusting_test_ca() { # the command, with the test authority as the only trusted certificate
    bwrap --dev-bind / / --tmpfs /etc/ssl --ro-bind "$work/ca.pem" /etc/ssl/certs/ca-certificates.crt "$@"
}

net_root net-http "http://127.0.0.1:$http_port"
"$dave" --root net-http install hello | expect "http" "install  hello  2.0-r1"
[[ $(cat net-http/usr/bin/hello) == "hello v2" ]] || fail "nothing installed over http"

net_root net-https "https://127.0.0.1:$here_port/"
trusting_test_ca "$dave" --root net-https install hello | expect "https" "install  hello  2.0-r1"
[[ $(cat net-https/usr/bin/hello) == "hello v2" ]] || fail "nothing installed over https"

net_root net-untrusted "https://127.0.0.1:$here_port"
out=$("$dave" --root net-untrusted install hello 2>&1) && fail "trusted a certificate outside the system's store"
expect "untrusted" "cannot connect securely to https://127.0.0.1:$here_port" <<<"$out"
[[ ! -e net-untrusted/usr/bin/hello ]] || fail "installed from an untrusted server"

net_root net-wrong-name "https://127.0.0.1:$elsewhere_port"
out=$(trusting_test_ca "$dave" --root net-wrong-name install hello 2>&1) && fail "accepted a certificate for another name"
expect "wrong name" "cannot connect securely" <<<"$out"
[[ ! -e net-wrong-name/usr/bin/hello ]] || fail "installed from a server with another name's certificate"
kill $server

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

echo "== a failed seal pass invalidates an old completion marker"
printf '' > root/usr/lib/dave/sealed
out=$("${D[@]}" seal 2>&1) && fail "sealed a root containing unsigned packages"
expect "strict seal" "missing, malformed, or unreadable seals" <<<"$out"
[[ ! -e root/usr/lib/dave/sealed ]] || fail "failed seal pass wrote its completion marker"

echo "cli tests passed"
