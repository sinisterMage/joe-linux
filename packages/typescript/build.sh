# There is no book page. TypeScript is written in TypeScript, so the only way
# to have it without already having it is upstream's npm package, which holds
# the compiler compiled to JavaScript and nothing else to fetch. It is laid
# out where "npm install -g typescript" would put it.
#
# 5.9.3 is the last release of the 5 series, which is what Decibels (the one
# user, at build time only) asks for ("^5.7.3"). TypeScript 6 rejects options
# its tsconfig.json uses, and TypeScript 7 is a native program distributed as
# prebuilt binaries.
package() {
    local dir=$DESTDIR/usr/lib/node_modules/typescript
    install -d "$dir" "$DESTDIR/usr/bin"
    cp -r bin lib package.json LICENSE.txt ThirdPartyNoticeText.txt "$dir/"
    chmod 755 "$dir/bin/tsc" "$dir/bin/tsserver"
    ln -s ../lib/node_modules/typescript/bin/tsc "$DESTDIR/usr/bin/tsc"
    ln -s ../lib/node_modules/typescript/bin/tsserver "$DESTDIR/usr/bin/tsserver"
}
