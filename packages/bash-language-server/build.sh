# Not in the book: the newest release, as upstream publishes it on npm (the
# server compiled from TypeScript), with its dependencies from upstream's
# lockfile, vendored as sources (see package.zon), laid out where
# "npm install -g bash-language-server" would put them.
#
# Upstream's repository locks its dependencies with pnpm, which npm cannot
# read, and joe has no pnpm; but the lockfile pins every package and its
# integrity, so the packages are sources here and nothing is fetched.

# The dependency tarballs, in package.zon's order. Each is unpacked into
# node_modules under the name its package.json gives.
_deps=(
    mixmark-io-domino-2.2.0.tgz
    nodelib-fs.scandir-2.1.5.tgz
    nodelib-fs.stat-2.0.5.tgz
    nodelib-fs.walk-1.2.8.tgz
    one-ini-wasm-0.2.1.tgz
    balanced-match-4.0.4.tgz
    brace-expansion-5.0.12.tgz
    braces-3.0.3.tgz
    commander-14.0.3.tgz
    editorconfig-3.0.2.tgz
    fast-glob-3.3.3.tgz
    fastq-1.15.0.tgz
    fill-range-7.1.1.tgz
    fuzzy-search-3.2.1.tgz
    glob-parent-5.1.2.tgz
    is-extglob-2.1.1.tgz
    is-glob-4.0.3.tgz
    is-number-7.0.0.tgz
    merge2-1.4.1.tgz
    micromatch-4.0.8.tgz
    minimatch-10.2.6.tgz
    picomatch-2.3.2.tgz
    queue-microtask-1.2.3.tgz
    reusify-1.0.4.tgz
    run-parallel-1.2.0.tgz
    semver-7.8.5.tgz
    to-regex-range-5.0.1.tgz
    turndown-7.2.4.tgz
    vscode-jsonrpc-9.0.2.tgz
    vscode-languageserver-protocol-3.18.3.tgz
    vscode-languageserver-textdocument-1.0.14.tgz
    vscode-languageserver-types-3.18.3.tgz
    vscode-languageserver-10.1.1.tgz
    web-tree-sitter-0.27.0.tgz
    zod-3.25.76.tgz
)

build() {
    local f name tmp
    mkdir node_modules
    for f in "${_deps[@]}"; do
        tmp=$(mktemp -d "$PWD/.dep.XXXXXX")
        tar -xf "$SOURCES/$f" -C "$tmp" --strip-components=1 --no-same-owner --no-same-permissions
        name=$(node -p 'require(process.argv[1]).name' "$tmp/package.json")
        [[ ! -e node_modules/$name ]] || { echo "$name is in two tarballs" >&2; return 1; }
        [[ $name != */* ]] || mkdir -p "node_modules/${name%/*}"
        mv "$tmp" "node_modules/$name"
    done
}

package() {
    local dir=$DESTDIR/usr/lib/node_modules/bash-language-server
    install -d "$dir" "$DESTDIR/usr/bin"
    # The TypeScript sources and the compiler's build state are left out.
    cp -r out node_modules package.json parser.info tree-sitter-bash.wasm "$dir/"
    find "$dir" -type d -exec chmod 755 {} +
    chmod 755 "$dir/out/cli.js" "$dir/out/get-options.sh"
    ln -s ../lib/node_modules/bash-language-server/out/cli.js "$DESTDIR/usr/bin/bash-language-server"
}
