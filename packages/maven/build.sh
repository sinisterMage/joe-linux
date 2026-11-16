# Not in the book: the newest release, built as its README says ("mvn
# -DdistributionTargetDir=... package"), with the previous release as the
# Maven that builds it, and installed where Fedora puts it: the
# distribution in /usr/share/maven, its configuration (settings.xml,
# toolchains.xml, logging) in /etc/maven, mvn and mvnDebug linked into
# /usr/bin. mvn finds its home through the link.

_maven_env() {
    export JAVA_HOME=/usr/lib/jvm/default
    # Keep Maven away from root's home in the shared build root.
    export HOME="$PWD/.home"
}

prepare() {
    # Only its jars and scripts are used; nothing of it is installed.
    mkdir .stage0
    tar -xf "$SOURCES/apache-maven-3.10.0-bin.tar.gz" -C .stage0 --strip-components=1 \
        --no-same-owner --no-same-permissions
}

build() {
    _maven_env
    # -DskipTests: the test suites are not run (they are still compiled,
    #   since modules depend on each other's test classes).
    # -DbuildNumber: the commit of the maven-3.10.1 tag, which mvn
    #   --version prints; buildnumber-maven-plugin would ask git for it.
    # -Drat.skip: Apache RAT would flag the stage0 and the local
    #   repository inside the source tree as files without a licence.
    .stage0/bin/mvn --batch-mode --no-transfer-progress \
        -Dmaven.repo.local="$PWD/.m2/repository" \
        -DdistributionTargetDir="$PWD/.dist" \
        -DbuildNumber=3afd8084b5629f80b97750906a719879ed4cd283 \
        -DskipTests \
        -Drat.skip=true \
        package
}

package() {
    local m=$DESTDIR/usr/share/maven
    install -d "$m" "$DESTDIR/usr/bin" "$DESTDIR/etc"
    cp -r .dist/. "$m/"
    # The Windows scripts.
    rm -v "$m"/bin/*.cmd

    mv "$m/conf" "$DESTDIR/etc/maven"
    ln -s /etc/maven "$m/conf"

    ln -s ../share/maven/bin/mvn "$DESTDIR/usr/bin/mvn"
    ln -s ../share/maven/bin/mvnDebug "$DESTDIR/usr/bin/mvnDebug"
}
