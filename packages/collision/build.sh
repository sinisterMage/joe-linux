# Not in the book: newest upstream release, following its Makefile and
# data/dev.geopjr.Collision.json, but vendoring every shard for offline builds.
# The native package keeps all checksum algorithms, concurrent calculation,
# drag-and-drop, file-to-file and checksum-list comparison, and GSettings.

prepare() {
    local name archive
    mkdir lib
    while read -r name archive; do
        mkdir "lib/$name"
        tar -xf "$SOURCES/$archive.tar.gz" -C "lib/$name" --strip-components=1 \
            --no-same-owner --no-same-permissions
        ln -snf .. "lib/$name/lib"
    done <<'SHARDS'
blake3 blake3-cr-1.4.0
gettext gettext-cr-1.0.0
gi-crystal gi-crystal-0.25.1
gtk4 gtk4-cr-0.18.0
harfbuzz harfbuzz-cr-0.2.1
libadwaita libadwaita-cr-0.1.0
pango pango-cr-0.3.1
SHARDS
    # Native installation: use argv, not a shell command assembled from
    # filenames; the extension does not need to probe or launch Flatpak.
    patch -Np1 -i /recipe/native-nautilus.patch
}

build() {
    export CRYSTAL_CACHE_DIR="$PWD/.crystal-cache"
    mkdir bin
    (
        cd lib/gi-crystal
        crystal build --release --no-debug src/generator/main.cr -o ../../bin/gi-crystal
    )
    ./bin/gi-crystal

    # Build the bundled official BLAKE3 implementation explicitly. Its Crystal
    # helper otherwise tries to put unassembled .S files into the archive.
    cmake -S lib/blake3/blake3c -B blake3-build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TESTING=OFF \
        -DBLAKE3_USE_TBB=OFF \
        -DBLAKE3_FETCH_TBB=OFF
    cmake --build blake3-build -j "$JOBS"
    cp blake3-build/libblake3.a lib/blake3/blake3c/libblake3.a

    COLLISION_LOCALE_LOCATION=/usr/share/locale BLAKE3_CR_DO_NOT_BUILD=1 \
        crystal build -Dpreview_mt -Dexecution_context -Denable_gschema \
        --release --no-debug src/collision.cr -o bin/collision
    msgfmt --desktop --template data/dev.geopjr.Collision.desktop.in -d po \
        -o data/dev.geopjr.Collision.desktop
    msgfmt --xml --template data/dev.geopjr.Collision.metainfo.xml.in -d po \
        -o data/dev.geopjr.Collision.metainfo.xml
}

package() {
    local app=dev.geopjr.Collision lang
    install -Dm755 bin/collision "$DESTDIR/usr/bin/collision"
    install -Dm644 "data/$app.desktop" "$DESTDIR/usr/share/applications/$app.desktop"
    install -Dm644 "data/$app.metainfo.xml" "$DESTDIR/usr/share/metainfo/$app.metainfo.xml"
    install -Dm644 "data/$app.gschema.xml" "$DESTDIR/usr/share/glib-2.0/schemas/$app.gschema.xml"
    install -Dm644 "data/icons/$app.svg" "$DESTDIR/usr/share/icons/hicolor/scalable/apps/$app.svg"
    install -Dm644 "data/icons/$app-symbolic.svg" "$DESTDIR/usr/share/icons/hicolor/symbolic/apps/$app-symbolic.svg"
    install -Dm644 nautilus-extension/collision-extension.py \
        "$DESTDIR/usr/share/nautilus-python/extensions/collision-extension.py"
    mkdir -p po/mo
    while read -r lang; do
        [[ -z $lang || $lang == \#* || $lang == en ]] && continue
        msgfmt "po/$lang.po" -o "po/mo/$lang.mo"
        install -Dm644 "po/mo/$lang.mo" "$DESTDIR/usr/share/locale/$lang/LC_MESSAGES/$app.mo"
    done < po/LINGUAS
    install -Dm644 LICENSE "$DESTDIR/usr/share/licenses/collision/LICENSE"
    for lang in lib/*; do
        install -Dm644 "$lang/LICENSE" "$DESTDIR/usr/share/licenses/collision/$(basename "$lang")-LICENSE"
    done
    install -Dm644 lib/blake3/blake3c/LICENSE "$DESTDIR/usr/share/licenses/collision/blake3c-LICENSE"
    # glib/gtk4 own the schema, desktop and icon cache triggers; do not
    # generate or package machine-local caches here.
}
