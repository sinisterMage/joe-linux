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
expect_re() { # expect_re <description> <extended regex> <<< haystack
    local text; text=$(cat)
    grep -qE -- "$2" <<<"$text" || fail "$1: expected /$2/ in: $text"
}
refuse() { # refuse <description> <needle> <<< haystack
    local text; text=$(cat)
    ! grep -qF -- "$2" <<<"$text" || fail "$1: did not expect '$2' in: $text"
}

declare -A about=([hello]="says hello" [libgreet]="greetings for hello" [tree]="lists directories")

# make_pkg <name> <version> <file> <content> [depends...]
make_pkg() {
    local name=$1 version=$2 file=$3 content=$4; shift 4
    local stage=$work/stage/$name-$version
    mkdir -p "$stage/$(dirname "$file")"
    printf '%s\n' "$content" > "$stage/$file"
    local deps=()
    for d in "$@"; do deps+=(--depends "$d"); done
    "$dave" pack --name "$name" --version "$version" --license MIT --description "${about[$name]:-}" \
        --out "$work/repo" "${deps[@]}" "$stage" >/dev/null
}

"$dave" key generate "$work/signing" >/dev/null
cp "$work/signing.pub" root/etc/dave/keys/
cat > root/etc/dave/repos.zon <<EOF
.{ .repos = .{ .{ .name = "test", .url = "$work/repo" } } }
EOF
D=("$dave" --root "$work/root")

echo "== help and version"
"$dave" | expect "overview" "Run 'dave help <command>'"
"$dave" --help | expect "--help" "Finding out"
"$dave" -h | expect "-h" "Every command takes"
"$dave" | refuse "hidden commands" "  finalize"
"$dave" help install | expect "help install" "Usage: dave install [options] <package>..."
"$dave" install --help | expect "install --help" "--dry-run"
"$dave" remove -h | expect "remove -h" "Usage: dave remove"
"$dave" help finalize | expect "hidden commands" "dave-finalize.service"
version=$("$dave" version)
[[ $version =~ ^dave\ [0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "dave version says: $version"
[[ $("$dave" --version) == "$version" && $("$dave" -V) == "$version" && $("$dave" install --version) == "$version" ]] ||
    fail "--version, -V and dave version disagree"
if [[ -z ${DAVE:-} ]]; then
    # What `dave version` says, what the package is and what the release is
    # named after must agree; tests/vm/live.py checks the same in a VM.
    packaged=$(sed -n 's/^ *\.version = "\(.*\)",/\1/p' "$top/packages/dave/package.zon")
    released=$(sed -n 's/.*local kernel=[^ ]* dave=\([^ ]*\).*/\1/p' "$top/packages/joe-release/build.sh")
    [[ $version == "dave $packaged" && $packaged == "$released" ]] ||
        fail "dave's version: the binary says '$version', packages/dave '$packaged', joe-release '$released'"
fi
out=$("$dave" isntall hello 2>&1) && fail "accepted a mistyped command"
expect "command suggestion" "did you mean 'install'?" <<<"$out"
out=$("$dave" help isntall 2>&1) && fail "explained a mistyped command"
expect "help suggestion" "did you mean 'install'?" <<<"$out"
out=$("$dave" install --dryrun hello 2>&1) && fail "accepted a mistyped option"
expect "option suggestion" "did you mean --dry-run?" <<<"$out"
out=$("$dave" list --disk x 2>&1) && fail "accepted another command's option"
expect "scoped option" "list does not take --disk (it is for install-system)" <<<"$out"
out=$("$dave" list --root 2>&1) && fail "accepted an option without its value"
expect "missing value" "--root needs a value (DIR)" <<<"$out"

echo "== the manual page names every command and option"
man=$top/dave/share/dave.8
for cmd in $("$dave" complete 1 dave "" | cut -f1); do
    grep -qE "^\.B[IR]? \"?$cmd( |\"|$)" "$man" || fail "dave.8 does not describe $cmd"
    for option in $("$dave" help "$cmd" | grep -oE -- '--[a-z][a-z-]*' | sort -u); do
        grep -qF -- "${option//-/\\-}" "$man" || fail "dave.8 does not describe $option (of $cmd)"
    done
done

make_pkg libgreet 1.0-r1 usr/lib/libgreet.txt "greet v1"
make_pkg hello 1.0-r1 usr/bin/hello "hello v1" "libgreet >=1.0"
make_pkg tree 2.2-r1 usr/bin/tree "tree"
make_pkg broken 1.0-r1 usr/bin/broken "x" "libgreet >=9"
"$dave" repo index "$work/repo" --key "$work/signing.key" | expect "index" "Indexed 4 package(s)."

echo "== install pulls in dependencies"
out=$("${D[@]}" install hello)
expect_re "plan" '^  hello +1\.0-r1$' <<<"$out"
expect_re "plan" '^  libgreet +1\.0-r1 +\(dependency\)$' <<<"$out"
expect "plan summary" "2 to install." <<<"$out"
[[ $(cat root/usr/bin/hello) == "hello v1" ]] || fail "hello not installed"
[[ $(cat root/usr/lib/libgreet.txt) == "greet v1" ]] || fail "dependency not installed"
"${D[@]}" list | expect "list" "libgreet 1.0-r1  (dependency)"
"${D[@]}" list | expect "list" "hello 1.0-r1"
[[ $(cat root/etc/dave/world) == "hello" ]] || fail "world not recorded"
"${D[@]}" install hello | expect "idempotent" "Already installed."

echo "== questions about what is installed"
"${D[@]}" list --requested | expect "list --requested" "hello 1.0-r1"
"${D[@]}" list --requested | refuse "list --requested" "libgreet"
out=$("${D[@]}" info libgreet)
expect_re "info" '^Installed +1\.0-r1, because hello needs it$' <<<"$out"
expect_re "info" '^Available +1\.0-r1, from test$' <<<"$out"
expect_re "info" '^Required by +hello$' <<<"$out"
expect_re "info" '^Licence +MIT$' <<<"$out"
out=$("${D[@]}" info tree)
expect_re "info, not installed" '^Installed +no$' <<<"$out"
expect_re "info, not installed" '^Installed size +5 B$' <<<"$out"
out=$("${D[@]}" info helo 2>&1) && fail "described a package that does not exist"
expect "info suggestion" "did you mean hello?" <<<"$out"
out=$("${D[@]}" search hello)
[[ $(head -n1 <<<"$out") =~ ^hello\ +1\.0-r1\ +\[installed\]\ +says\ hello$ ]] || fail "search: the name match is not first: $out"
expect "search by description" "libgreet" <<<"$out"
out=$("${D[@]}" search hello greet)
[[ $out =~ ^libgreet\  && $(wc -l <<<"$out") -eq 1 ]] || fail "search hello greet: $out"
out=$("${D[@]}" search nothing-like-this 2>&1) && fail "a search without a match succeeded"
expect "search, no match" "no package matches nothing-like-this" <<<"$out"
"${D[@]}" files hello | expect "files" "/usr/bin/hello"
"${D[@]}" files hello | expect "files, directories" "/usr/bin/"
"${D[@]}" owns /usr/bin/hello | expect "owns" "/usr/bin/hello is owned by hello 1.0-r1."
ln -s usr/bin root/bin
"${D[@]}" owns /bin/hello | expect "owns, through a link" "/bin/hello (/usr/bin/hello) is owned by hello 1.0-r1."
rm root/bin
"${D[@]}" owns /usr | expect "owns, shared" "/usr is a directory shared by 2 packages: hello and libgreet."
out=$("${D[@]}" owns /etc/nothing 2>&1) && fail "owns found an owner for nothing"
expect "owns, nothing" "no installed package owns /etc/nothing" <<<"$out"
"${D[@]}" why libgreet | expect "why" "libgreet is here because you asked for hello, which needs it."
"${D[@]}" why hello | expect "why, requested" "hello is here because you asked for it."

echo "== mistakes are caught before anything changes"
out=$("${D[@]}" install helo 2>&1) && fail "installed a mistyped package"
expect "package suggestion" "no package named helo exists; did you mean hello?" <<<"$out"
out=$("${D[@]}" remove helo 2>&1) && fail "removed a package that is not installed"
expect "remove suggestion" "helo is not installed; did you mean hello?" <<<"$out"
"${D[@]}" install --dry-run tree | expect_re "dry run" '^  tree +2\.2-r1$'
[[ ! -e root/usr/bin/tree ]] || fail "a dry run installed tree"
[[ $(cat root/etc/dave/world) == "hello" ]] || fail "a dry run changed the world"
mkdir -p fresh/etc/dave
cp -r root/etc/dave/keys root/etc/dave/repos.zon fresh/etc/dave/
"$dave" --root fresh --dry-run install tree | expect_re "dry run, nothing fetched yet" '^  tree +2\.2-r1$'
[[ ! -e fresh/usr/bin/tree && ! -e fresh/etc/dave/world ]] || fail "a dry run changed a fresh root"
if [[ $(id -u) -ne 0 ]]; then
    out=$("$dave" install hello 2>&1) && fail "installed into / without root"
    expect "root" "installing packages needs root; run it with sudo: sudo dave install hello" <<<"$out"
    out=$("$dave" rollback 2>&1) && fail "rolled back without root"
    expect "root" "sudo dave rollback" <<<"$out"
fi

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
"${D[@]}" install tree | expect_re "no unrelated upgrades" '^  tree +2\.2-r1$'
[[ $(cat root/usr/bin/hello) == "hello v1" ]] || fail "install upgraded an unrelated package"
"${D[@]}" upgrade --check | expect_re "upgrade --check" '^  hello +1\.0-r1 -> 2\.0-r1$'
[[ $(cat root/usr/bin/hello) == "hello v1" ]] || fail "upgrade --check upgraded"
"${D[@]}" upgrade | expect_re "upgrade" '^  hello +1\.0-r1 -> 2\.0-r1$'
[[ $(cat root/usr/bin/hello) == "hello v2" ]] || fail "hello not upgraded"
[[ $(cat root/usr/lib/libgreet.txt) == "greet v1.1" ]] || fail "libgreet not upgraded"
"${D[@]}" upgrade | expect "up to date" "Everything is up to date."

echo "== remove takes orphaned dependencies along"
out=$("${D[@]}" remove libgreet 2>&1) && fail "removed a dependency directly"
expect "dependency" "libgreet was not installed by request; it is here because hello needs it" <<<"$out"
"${D[@]}" remove hello | expect_re "orphan" '^  libgreet +1\.1-r1 +\(no longer needed\)$'
[[ ! -e root/usr/bin/hello && ! -e root/usr/lib/libgreet.txt ]] || fail "files left behind"
[[ -e root/usr/bin/tree ]] || fail "unrelated package removed"

echo "== shell completion"
completing() { "$dave" complete "$@" | cut -f1; }
[[ $(completing 1 dave inf) == info ]] || fail "completing a command: $(completing 1 dave inf)"
completing 4 dave --root "$work/root" install "" | expect "available packages" "hello"
[[ $(completing 4 dave --root "$work/root" remove "") == tree ]] || fail "completing what can be removed"
completing 2 dave install --dr | expect "options" "--dry-run"
[[ $(completing 2 dave owns /u) == :files ]] || fail "completing a path"
[[ -z $(completing 3 dave deployments pin "") ]] || fail "completed a deployment id"
share=$top/dave/share
bash -n "$share/completion.bash"
if command -v zsh >/dev/null; then zsh -n "$share/completion.zsh"; fi
if command -v fish >/dev/null; then fish --no-execute "$share/completion.fish"; fi
out=$(PATH=$(dirname "$dave"):$PATH bash -c 'source "$1"; COMP_WORDS=(dave --root "$2" install he); COMP_CWORD=4; _dave
    printf "%s\n" "${COMPREPLY[@]}"' _ "$share/completion.bash" "$work/root")
[[ $out == hello ]] || fail "bash completion of 'install he': $out"

echo "== questions and colour on a terminal"
mkdir -p "$work/bin"
cat > "$work/bin/tty.py" <<'EOF'
# tty.py ANSWER COMMAND...: runs COMMAND on a pseudo-terminal, typing ANSWER
# (y or n) if it asks "[Y/n]". With ANSWER "none", a question is answered n
# and reported. Prints what COMMAND wrote and exits with its status.
import os, pty, sys
answer, *argv = sys.argv[1:]
pid, fd = pty.fork()
if pid == 0:
    os.execvp(argv[0], argv)
out, asked = b"", False
while True:
    try:
        data = os.read(fd, 4096)
    except OSError:
        break
    if not data:
        break
    out += data
    if not asked and b"[Y/n]" in out:
        asked = True
        os.write(fd, (b"n" if answer == "none" else answer.encode()) + b"\n")
_, status = os.waitpid(pid, 0)
sys.stdout.write(out.decode(errors="replace").replace("\r\n", "\n"))
if answer == "none" and asked:
    print("UNEXPECTED QUESTION")
sys.exit(os.waitstatus_to_exitcode(status))
EOF
on_tty() { python3 -I "$work/bin/tty.py" "$@"; }
mkdir -p tty/etc/dave
cp -r root/etc/dave/keys root/etc/dave/repos.zon tty/etc/dave/
out=$(TERM=dumb on_tty n "${D[0]}" --root tty install hello) && fail "went ahead after being told no"
expect "declined" "Continue? [Y/n]" <<<"$out"
expect "declined" "Nothing was changed." <<<"$out"
[[ ! -e tty/usr/bin/hello && ! -e tty/etc/dave/world ]] || fail "a declined install changed the root"
out=$(TERM=dumb on_tty none "${D[0]}" --root tty install tree)
refuse "exactly what was named" "UNEXPECTED QUESTION" <<<"$out"
[[ -e tty/usr/bin/tree ]] || fail "tree was not installed"
out=$(TERM=xterm on_tty none "${D[0]}" --root tty install -y hello)
refuse "--yes" "UNEXPECTED QUESTION" <<<"$out"
[[ $out == *$'\e[32m'* ]] || fail "no colour on a terminal: $out"
[[ -e tty/usr/bin/hello ]] || fail "hello was not installed"
out=$(NO_COLOR=1 TERM=xterm on_tty none "${D[0]}" --root tty info hello)
[[ $out != *$'\e['* ]] || fail "colour despite NO_COLOR: $out"
out=$(TERM=dumb on_tty y "${D[0]}" --root tty remove hello)
expect "asked, as libgreet goes too" "Continue? [Y/n]" <<<"$out"
[[ $out != *$'\e['* ]] || fail "escape sequences for TERM=dumb: $out"
[[ ! -e tty/usr/bin/hello && ! -e tty/usr/lib/libgreet.txt ]] || fail "the removal answered yes did not happen"
CLICOLOR_FORCE=1 "$dave" --root tty info tree | expect "CLICOLOR_FORCE" $'\e[1m'

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
"$dave" --root net-http install hello | expect_re "http" '^  hello +2\.0-r1$'
[[ $(cat net-http/usr/bin/hello) == "hello v2" ]] || fail "nothing installed over http"

net_root net-https "https://127.0.0.1:$here_port/"
trusting_test_ca "$dave" --root net-https install hello | expect_re "https" '^  hello +2\.0-r1$'
[[ $(cat net-https/usr/bin/hello) == "hello v2" ]] || fail "nothing installed over https"

net_root net-untrusted "https://127.0.0.1:$here_port"
out=$("$dave" --root net-untrusted install hello 2>&1) && fail "trusted a certificate outside the system's store"
expect "untrusted" "cannot connect securely to https://127.0.0.1:$here_port" <<<"$out"
[[ ! -e net-untrusted/usr/bin/hello ]] || fail "installed from an untrusted server"

net_root net-wrong-name "https://127.0.0.1:$elsewhere_port"
out=$(trusting_test_ca "$dave" --root net-wrong-name install hello 2>&1) && fail "accepted a certificate for another name"
expect "wrong name" "cannot connect securely" <<<"$out"
[[ ! -e net-wrong-name/usr/bin/hello ]] || fail "installed from a server with another name's certificate"

net_root net-refused "http://127.0.0.1:1"
out=$("$dave" --root net-refused install hello 2>&1) && fail "installed from a server that is not there"
expect "refused" "the connection was refused" <<<"$out"
net_root net-missing "http://127.0.0.1:$http_port/nowhere"
out=$("$dave" --root net-missing install hello 2>&1) && fail "installed from a repository that is not there"
expect "not found" "nowhere/repo.zon answered 404 Not Found" <<<"$out"
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

echo "== a disk image from a specification"
PATH=$top/build/host-tools/bin:$PATH
missing=
for tool in mkfs.btrfs mkfs.vfat mcopy mtype mdir sfdisk unshare; do
    command -v "$tool" >/dev/null || missing+=" $tool"
done
if [[ -n $missing ]]; then
    echo "   skipped, missing:$missing (make build/host-tools/bin/mcopy builds mtools)"
else
    # The tampered package of an earlier test, made whole again.
    rm -f "$work/repo/hello-2.0-r1-x86_64.dave"
    make_pkg hello 2.0-r1 usr/bin/hello "hello v2" "libgreet >=1.1"
    make_pkg kernel 1.0-r1 usr/lib/modules/1.0-test/vmlinuz "a kernel"
    make_pkg loader 1.0-r1 usr/lib/systemd/boot/efi/systemd-bootx64.efi "MZ #### LoaderInfo: systemd-boot 262.1 ####"
    make_pkg varstate 1.0-r1 var/lib/varstate/state "shared state"
    "$dave" repo index "$work/repo" --key "$work/signing.key" >/dev/null
    repo_arg="test,$work/repo,http://example.invalid/x86_64,$work/signing.pub"

    printf '.{ .name = "typo", .packages = .{"hello"}, .rootsize = "1G" }\n' > typo.zon
    out=$("$dave" image build typo.zon --repo "$repo_arg" --out typo.img 2>&1) && fail "accepted a misspelt spec field"
    expect "strict spec" "rootsize" <<<"$out"

    cat > image.zon <<'EOF'
.{
    .name = "cli",
    .packages = .{ "kernel", "loader", "hello", "varstate" },
    .root_size = "256M",
    .esp_size = "64M",
    .cmdline = "console=ttyS0,115200",
}
EOF
    "$dave" image build image.zon --repo "$repo_arg" --out disk.img | expect "built" "image ready: disk.img"
    [[ ! -e disk.img.work ]] || fail "the image build left its work directory"
    [[ $(stat -c %s disk.img) -eq $(( (1 + 64 + 256 + 1) << 20 )) ]] || fail "unexpected image size $(stat -c %s disk.img)"
    dump=$(sfdisk --dump disk.img)
    expect "esp partition" "type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B" <<<"$dump"
    expect "root partition" "type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709" <<<"$dump"
    root_uuid=$(sed -n 's/.*type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709, uuid=\([0-9A-Fa-f-]*\).*/\1/p' <<<"$dump")
    [[ -n $root_uuid ]] || fail "no root partition uuid in: $dump"

    # The ESP is the partition at 1 MiB.
    esp="disk.img@@1M"
    entry=$(mtype -i "$esp" ::/loader/entries/joe-1.conf)
    expect "entry" "rootflags=subvol=joe/deploy/1 rw rootwait panic=10 loglevel=4 console=ttyS0,115200" <<<"$entry"
    grep -qi "root=PARTUUID=$root_uuid " <<<"$entry" || fail "the boot entry does not name the root partition: $entry"
    kernel=$(sed -n 's/^linux //p' <<<"$entry")
    [[ $(mtype -i "$esp" "::$kernel") == "a kernel" ]] || fail "the entry's kernel is not the root's kernel"
    mdir -i "$esp" ::/EFI/BOOT | expect "fallback loader" "BOOTX64"
    mdir -i "$esp" ::/EFI/systemd | expect "loader" "SYSTEM~1"
    expect "loader.conf" "editor no" <<<"$(mtype -i "$esp" ::/loader/loader.conf)"

    # The root partition: deployment 1 plus the shared subvolumes, and /var's
    # contents moved out of the deployment into its own.
    dd if=disk.img of=root.img bs=1M skip=65 count=256 status=none
    tree=$(btrfs inspect-internal dump-tree -t fs_tree root.img 2>/dev/null; btrfs inspect-internal dump-tree -t root root.img 2>/dev/null)
    for name in "name: 1" "name: home" "name: var"; do
        grep -qF "$name" <<<"$tree" || fail "the root file system lacks a subvolume ($name)"
    done
    rm -f root.img
fi

echo "== a live medium from a specification"
missing=
for tool in xorriso mksquashfs unsquashfs mkfs.vfat mcopy mtype sfdisk zstd cpio unshare; do
    command -v "$tool" >/dev/null || missing+=" $tool"
done
if [[ -n $missing ]]; then
    echo "   skipped, missing:$missing (make iso-tools builds xorriso and squashfs-tools)"
else
    make_pkg osrel 1.0-r1 usr/lib/os-release 'PRETTY_NAME="joe Linux test"'
    make_pkg extra 1.0-r1 usr/bin/extra "extra"
    "$dave" repo index "$work/repo" --key "$work/signing.key" >/dev/null
    mkdir -p initrd-overlay/etc
    echo 'NAME="test initrd"' > initrd-overlay/etc/initrd-release
    ln -sfn usr/bin/hello initrd-overlay/init
    # The installer copies what it installs out of the live root, so the
    # payload must be installed there; the live session's changes to its
    # files (here, the overlay's) are kept on the medium as packaged.
    mkdir -p live-overlay/usr/bin
    echo "changed by the live session" > live-overlay/usr/bin/tree
    cat > live.zon <<'EOF'
.{
    .name = "cli-live",
    .format = .iso,
    .packages = .{ "kernel", "loader", "osrel", "hello", "tree" },
    .overlay = "live-overlay",
    .cmdline = "quiet",
    .iso = .{
        .label = "JOE_TEST",
        .initrd = .{ .packages = .{"hello"}, .overlay = "initrd-overlay", .remove = .{"usr/lib/libgreet.txt"} },
        .payload = .{ "hello", "tree" },
    },
}
EOF
    live_repo=${repo_arg:-test,$work/repo,http://example.invalid/x86_64,$work/signing.pub}
    out=$("$dave" image build live.zon --repo "$live_repo" --out live.iso)
    expect "built" "image ready: live.iso" <<<"$out"
    expect "changed file" "the live root changes usr/bin/tree (tree)" <<<"$out"
    expect "payload" "installs 3 packages from its root" <<<"$out"

    # The ISO 9660 file system: the root image, what the installer installs,
    # and the original of the file the live root changed; no package files.
    listing=$(xorriso -indev live.iso -find / -type f 2>/dev/null)
    original=$(printf 'tree\n' | sha256sum | cut -d' ' -f1)
    for path in /joe/root.squashfs /joe/install.zon "/joe/originals/$original"; do
        expect "medium" "'$path'" <<<"$listing"
    done
    refuse "medium" ".dave" <<<"$listing"
    refuse "medium" "/joe/repos" <<<"$listing"
    xorriso -indev live.iso -osirrox on -extract /joe/install.zon install.zon -extract /joe/root.squashfs root.squashfs \
        -extract "/joe/originals/$original" original 2>/dev/null
    expect "install list" '"hello", "tree",' <<<"$(cat install.zon)"
    [[ $(cat original) == tree ]] || fail "the medium's original of usr/bin/tree is: $(cat original)"
    # The root image: xz-compressed SquashFS holding the spec's tree.
    expect "root image" "Compression xz" <<<"$(unsquashfs -s root.squashfs)"
    expect "root image" "squashfs-root/usr/bin/hello" <<<"$(unsquashfs -l root.squashfs)"

    # A payload the live root does not hold is refused.
    sed 's/payload = .{ "hello", "tree" }/payload = .{ "hello", "tree", "extra" }/' live.zon > lacking.zon
    out=$("$dave" image build lacking.zon --repo "$live_repo" --out lacking.iso 2>&1) && fail "built a medium whose root lacks its payload"
    expect "lacking payload" "the live root does not have extra" <<<"$out"
    [[ ! -e lacking.iso ]] || fail "a refused medium was written"

    # It boots from a CD (El Torito, EFI) and as a disk (GPT partition 2).
    xorriso -indev live.iso -report_el_torito plain 2>&1 | expect "el torito" "UEFI"
    dump=$(sfdisk --dump live.iso)
    expect "appended ESP" "type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B" <<<"$dump"
    start=$(sed -n 's/^live.iso2 : start= *\([0-9]*\),.*/\1/p' <<<"$dump")
    [[ -n $start ]] || fail "no second partition in: $dump"
    esp="live.iso@@$((start * 512))"
    entry=$(mtype -i "$esp" ::/loader/entries/joe-live.conf)
    expect "title" "title joe Linux test" <<<"$entry"
    expect "options" "options joe=log loglevel=4 systemd.gpt_auto=0 rd.systemd.gpt_auto=0 quiet" <<<"$entry"
    [[ $entry != *root=* ]] || fail "the live entry names a root: $entry"
    expect "safe graphics" "nomodeset" <<<"$(mtype -i "$esp" ::/loader/entries/joe-live-safe.conf)"
    initrd=$(sed -n 's/^initrd //p' <<<"$entry")
    mcopy -i "$esp" "::$initrd" initrd.img
    contents=$(zstd -dc initrd.img | cpio -t 2>/dev/null)
    for path in init dev/console etc/initrd-release usr/bin/hello; do
        grep -qx "$path" <<<"$contents" || fail "the initramfs lacks $path"
    done
    ! grep -q "libgreet.txt\|usr/lib/dave/db" <<<"$contents" || fail "the initramfs kept what the spec removes"
    rm -f root.squashfs initrd.img
fi

echo "== a container image from a specification"
if ! command -v unshare >/dev/null || [[ -z ${repo_arg:-} ]]; then
    echo "   skipped, missing: unshare, or the disk image's packages"
else
    cat > container.zon <<'EOF'
.{
    .name = "cli-container",
    .format = .oci,
    .packages = .{ "osrel", "hello" },
    .oci = .{
        .cmd = .{"/usr/bin/hello"},
        .labels = .{.{ .name = "org.opencontainers.image.source", .value = "https://example.invalid/joe" }},
    },
}
EOF
    "$dave" image build container.zon --repo "$repo_arg" --out container.tar | expect "built" "image ready: container.tar"
    printf '.{ .name = "x", .packages = .{"hello"}, .oci = .{} }\n' > misplaced.zon
    out=$("$dave" image build misplaced.zon --repo "$repo_arg" --out misplaced.img 2>&1) && fail "accepted .oci on a disk image"
    expect "misplaced .oci" ".oci is for .format = .oci" <<<"$out"

    # An OCI image layout: every blob named by its digest, the configuration
    # naming the uncompressed layer, the layer holding the tree.
    rm -rf oci && mkdir oci && tar -xf container.tar -C oci
    python3 -I - oci <<'EOF' || fail "the container image is not what it should be"
import gzip, hashlib, json, os, sys, tarfile
top = sys.argv[1]
def blob(ref, media):
    assert ref["mediaType"] == media, ref
    data = open(os.path.join(top, "blobs/sha256", ref["digest"].removeprefix("sha256:")), "rb").read()
    assert len(data) == ref["size"] and "sha256:" + hashlib.sha256(data).hexdigest() == ref["digest"], ref
    return data
assert json.load(open(os.path.join(top, "oci-layout")))["imageLayoutVersion"] == "1.0.0"
index = json.load(open(os.path.join(top, "index.json")))
manifest = json.loads(blob(index["manifests"][0], "application/vnd.oci.image.manifest.v1+json"))
config = json.loads(blob(manifest["config"], "application/vnd.oci.image.config.v1+json"))
layer = gzip.decompress(blob(manifest["layers"][0], "application/vnd.oci.image.layer.v1.tar+gzip"))
assert config["rootfs"]["diff_ids"] == ["sha256:" + hashlib.sha256(layer).hexdigest()], config["rootfs"]
assert config["config"]["Cmd"] == ["/usr/bin/hello"] and config["os"] == "linux" and config["architecture"] == "amd64"
assert config["config"]["Labels"]["org.opencontainers.image.source"] == "https://example.invalid/joe"
docker = json.load(open(os.path.join(top, "manifest.json")))
assert docker[0]["RepoTags"] == ["cli-container:latest"], docker
with tarfile.open(fileobj=__import__("io").BytesIO(layer)) as t:
    members = {m.name.removeprefix("./"): m for m in t.getmembers()}
    hello = members["usr/bin/hello"]
    assert hello.uid == 0 and hello.gid == 0 and t.extractfile(hello).read() == b"hello v2\n", hello
    repos = t.extractfile(members["etc/dave/repos.zon"]).read().decode()
    assert "http://example.invalid/x86_64" in repos, repos
    assert not any(n.startswith("var/cache/dave/") for n in members), "the package files were kept"
EOF
    rm -rf oci container.tar
fi

echo "cli tests passed"
