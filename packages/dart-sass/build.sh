# There is no book page. Dart Sass is written in Dart, which joe does not
# package; upstream's npm package is the same compiler compiled to
# JavaScript, which is what "npm install -g sass" installs. Its dependencies
# go in its own node_modules, so nothing else sees them. The sass program
# loads chokidar (for --watch) as it starts, so all of them are needed.
# libsass and sassc are a different, retired implementation: adw-gtk3 needs
# this one.
package() {
    local dir=$DESTDIR/usr/lib/node_modules/sass
    install -d "$dir/node_modules" "$DESTDIR/usr/bin"
    cp -r ./*.js ./*.cjs ./*.mjs package.json LICENSE types "$dir/"
    chmod 755 "$dir/sass.js"
    local dep
    for dep in chokidar-5.0.0 readdirp-5.1.1 immutable-5.2.1 source-map-js-1.2.2; do
        install -d "$dir/node_modules/${dep%-*}"
        tar -xzf "$SOURCES/$dep.tgz" --strip-components=1 -C "$dir/node_modules/${dep%-*}"
    done
    ln -s ../lib/node_modules/sass/sass.js "$DESTDIR/usr/bin/sass"
}
