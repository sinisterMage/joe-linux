# Not in the book: upstream's stable release, built with javac and jar as
# its build.xml specifies. All Java dependencies are system source builds.
prepare() {
    # Current Bouncy Castle decodes DL tags, not DER-only classes. Use typed
    # explicit/implicit decoders instead of the removed getObject() API.
    patch -Np1 -i /recipe/bouncycastle-current.patch
}

build() {
    export JAVA_HOME=/usr/lib/jvm/default
    mkdir -p build/classes
    find java -name '*.java' | sort > build/sources.txt
    # Upstream compiles for Java 8 (source and target 1.8).
    javac -encoding UTF-8 --release 8 -nowarn \
        -cp /usr/share/java/bcprov.jar:/usr/share/java/commons-lang3.jar \
        -d build/classes @build/sources.txt
    (cd java && find . \( -name '*.afm' -o -name '*.txt' \) -exec install -Dm644 {} ../build/classes/{} \;)
    jar --create --file build/pdftk.jar --main-class com.gitlab.pdftk_java.pdftk -C build/classes .
}

package() {
    install -Dm644 build/pdftk.jar "$DESTDIR/usr/share/pdftk/pdftk.jar"
    install -d "$DESTDIR/usr/bin"
    cat > "$DESTDIR/usr/bin/pdftk" <<'EOT'
#!/bin/sh
exec /usr/bin/java -cp /usr/share/pdftk/pdftk.jar:/usr/share/java/bcprov.jar:/usr/share/java/commons-lang3.jar com.gitlab.pdftk_java.pdftk "$@"
EOT
    chmod 755 "$DESTDIR/usr/bin/pdftk"
    install -Dm644 pdftk.1 "$DESTDIR/usr/share/man/man1/pdftk.1"
}
