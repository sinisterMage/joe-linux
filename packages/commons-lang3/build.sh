# Not in the book: compile the current upstream source-only archive with
# the system JDK. The library has no non-JDK runtime or compile dependencies.
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
    printf 'Manifest-Version: 1.0\nAutomatic-Module-Name: org.apache.commons.lang3\nImplementation-Version: %s\n' "$PKG_VERSION" > build/MANIFEST.MF
    jar --create --file build/commons-lang3.jar --manifest build/MANIFEST.MF -C build/classes .
}

package() {
    install -Dm644 build/commons-lang3.jar "$DESTDIR/usr/share/java/commons-lang3.jar"
    install -Dm644 META-INF/LICENSE.txt "$DESTDIR/usr/share/licenses/commons-lang3/LICENSE"
    install -Dm644 META-INF/NOTICE.txt "$DESTDIR/usr/share/licenses/commons-lang3/NOTICE"
}
