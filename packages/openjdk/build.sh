# BLFS's OpenJDK page, bootstrapped with the book's binary JDK. Instead of
# /opt/jdk-VERSION and a profile script, it is installed where most
# distributions put it, /usr/lib/jvm/java-25-openjdk (with a `default` link),
# and its commands are linked into /usr/bin. java finds its home from its own
# location, so neither JAVA_HOME nor PATH has to be set.

_jvm=usr/lib/jvm/java-25-openjdk

prepare() {
    mkdir .bootjdk
    tar -xf "$SOURCES/OpenJDK-25.0.5.0.3+1-x86_64-bin.tar.xz" -C .bootjdk --strip-components=1 \
        --no-same-owner --no-same-permissions
}

build() {
    unset JAVA_HOME CLASSPATH
    # The JDK's make runs its own jobs (--with-jobs) and refuses MAKEFLAGS.
    unset MAKEFLAGS
    # The book's options, plus: the bootstrap JDK above; no separate debug
    # symbols (the book deletes the .debuginfo files afterwards); and no
    # jtreg, which only the test suite uses.
    bash configure --enable-unlimited-crypto \
        --disable-warnings-as-errors \
        --with-stdc++lib=dynamic \
        --with-giflib=system \
        --with-harfbuzz=system \
        --with-lcms=system \
        --with-libjpeg=system \
        --with-libpng=system \
        --with-zlib=system \
        --with-version-build=1 \
        --with-version-pre="" \
        --with-version-opt="" \
        --with-jobs="$JOBS" \
        --with-boot-jdk="$PWD/.bootjdk" \
        --with-native-debug-symbols=none \
        --with-cacerts-file=/etc/pki/tls/java/cacerts
    make images
}

package() {
    install -d "$DESTDIR/$_jvm"
    cp -R build/*/images/jdk/* "$DESTDIR/$_jvm"
    find "$DESTDIR/$_jvm" -name '*.debuginfo' -delete
    ln -s java-25-openjdk "$DESTDIR/usr/lib/jvm/default"

    local f
    install -d "$DESTDIR/usr/bin"
    for f in "$DESTDIR/$_jvm"/bin/*; do
        ln -s "../lib/jvm/default/bin/${f##*/}" "$DESTDIR/usr/bin/${f##*/}"
    done

    # The manual pages, where man looks. The JDK makes them with pandoc,
    # which joe does not have; the image then has none.
    if [[ -d $DESTDIR/$_jvm/man/man1 ]]; then
        install -d "$DESTDIR/usr/share/man"
        mv "$DESTDIR/$_jvm/man/man1" "$DESTDIR/usr/share/man/man1"
        rmdir "$DESTDIR/$_jvm/man"
    fi

    # Trust what the system trusts: make-ca keeps this store current.
    ln -sf /etc/pki/tls/java/cacerts "$DESTDIR/$_jvm/lib/security/cacerts"

    # The book's icons and desktop entries, pointing at /usr/bin.
    local s
    for s in 16 24 32 48; do
        install -Dm644 "src/java.desktop/unix/classes/sun/awt/X11/java-icon$s.png" \
            "$DESTDIR/usr/share/icons/hicolor/${s}x$s/apps/java.png"
    done
    install -d "$DESTDIR/usr/share/applications"
    cat > "$DESTDIR/usr/share/applications/openjdk-java.desktop" << "EOT"
[Desktop Entry]
Name=OpenJDK Java 25.0.5.0.3 Runtime
Comment=OpenJDK Java 25.0.5.0.3 Runtime
Exec=/usr/bin/java -jar
Terminal=false
Type=Application
Icon=java
MimeType=application/x-java-archive;application/java-archive;application/x-jar;
NoDisplay=true
EOT
    cat > "$DESTDIR/usr/share/applications/openjdk-jconsole.desktop" << "EOT"
[Desktop Entry]
Name=OpenJDK Java 25.0.5.0.3 Console
Comment=OpenJDK Java 25.0.5.0.3 Console
Keywords=java;console;monitoring
Exec=/usr/bin/jconsole
Terminal=false
Type=Application
Icon=java
Categories=Application;System;
EOT
}
