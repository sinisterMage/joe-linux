# Not in the book: compile upstream's source-only provider archive with the
# system JDK. No prebuilt Maven classes, Gradle plugins or runtime jars ship.
unpack() {
    bsdtar -xf "$SOURCES/$PKG_SOURCE"
}

build() {
    mkdir -p build/classes
    find org -name '*.java' | sort > build/sources.txt
    javac -encoding UTF-8 --release 8 -d build/classes @build/sources.txt
    local resource
    while IFS= read -r -d '' resource; do
        install -Dm644 "$resource" "build/classes/$resource"
    done < <(find org -type f ! -name '*.java' -print0)
    printf 'Manifest-Version: 1.0\nAutomatic-Module-Name: org.bouncycastle.provider\nImplementation-Version: %s\n' "$PKG_VERSION" > build/MANIFEST.MF
    jar --create --file build/bcprov.jar --manifest build/MANIFEST.MF -C build/classes .
}

package() {
    install -Dm644 build/bcprov.jar "$DESTDIR/usr/share/java/bcprov.jar"
    install -Dm644 META-INF/LICENSE.md "$DESTDIR/usr/share/licenses/bouncycastle/LICENSE"
}
