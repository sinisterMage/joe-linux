# Not in the book: upstream source, compiled with Go, then its newly built
# binary generates the Node API from TypeScript via upstream's --neutral.
# No npm install/postinstall or prebuilt platform packages are used.
prepare() {
    # Only the packaged system executable is used. Upstream's release
    # helper hashes cross-platform binaries not present in source archives.
    sed -i "s/packageJSON\['esbuild.binaryHashes'\] = generateBinaryHashes()/packageJSON['esbuild.binaryHashes'] = {}/" scripts/esbuild.js
    sed -i 's/packageJSON.optionalDependencies = optionalDependencies/packageJSON.optionalDependencies = {}/' scripts/esbuild.js
    sed -i "s/process.env.ESBUILD_BINARY_PATH || ESBUILD_BINARY_PATH/process.env.ESBUILD_BINARY_PATH || '\/usr\/bin\/esbuild'/" lib/npm/node-platform.ts
    sed -i "s/!!x \&\& x !== '\/usr\/bin\/esbuild'/!!x/" lib/npm/node-platform.ts
}

build() {
    export GOTOOLCHAIN=local
    export GOPATH="$PWD/../go-path" GOMODCACHE="$PWD/../go-mod" GOCACHE="$PWD/../go-cache"
    go build -mod=readonly -trimpath -buildmode=pie -ldflags='-s -w' -o esbuild ./cmd/esbuild
    env -u DESTDIR node scripts/esbuild.js "$PWD/esbuild" --neutral
    # Distribution packages never run npm's binary-downloading postinstall.
    node -e 'const fs=require("fs"),p="npm/esbuild/package.json",j=JSON.parse(fs.readFileSync(p)); delete j.scripts; fs.writeFileSync(p,JSON.stringify(j,null,2)+"\n")'
}

package() {
    install -Dm755 esbuild "$DESTDIR/usr/bin/esbuild"
    install -d "$DESTDIR/usr/lib/node_modules/esbuild/lib"
    install -Dm755 npm/esbuild/bin/esbuild "$DESTDIR/usr/lib/node_modules/esbuild/bin/esbuild"
    install -m644 npm/esbuild/lib/main.{js,d.ts} "$DESTDIR/usr/lib/node_modules/esbuild/lib/"
    install -m644 npm/esbuild/package.json "$DESTDIR/usr/lib/node_modules/esbuild/"
    install -Dm644 LICENSE.md "$DESTDIR/usr/share/licenses/esbuild/LICENSE"
}
