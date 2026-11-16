# Not in the book: the newest release, as upstream publishes it on npm.
# Like TypeScript's, the npm package is the program already compiled from
# TypeScript and bundled (dist/), which is the only form that can be had
# without its build tools: building it from source needs npm's development
# dependencies, among them rspack, which is distributed as prebuilt native
# binaries. It is laid out where "npm install -g pyright" would put it.
package() {
    local dir=$DESTDIR/usr/lib/node_modules/pyright
    install -d "$dir" "$DESTDIR/usr/bin"
    cp -r dist index.js langserver.index.js package.json LICENSE.txt "$dir/"
    chmod 755 "$dir/index.js" "$dir/langserver.index.js"
    ln -s ../lib/node_modules/pyright/index.js "$DESTDIR/usr/bin/pyright"
    ln -s ../lib/node_modules/pyright/langserver.index.js "$DESTDIR/usr/bin/pyright-langserver"
}
