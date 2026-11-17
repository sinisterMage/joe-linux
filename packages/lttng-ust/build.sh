# Not in BLFS: latest stable upstream release, following its README.md.
# .NET needs the native tracepoint ABI, not the Java/Python logging agents.
# NUMA support is explicitly off: no libnuma recipe exists.
build() {
    ./configure --prefix=/usr --libdir=/usr/lib --disable-static \
        --disable-numa --disable-jni-interface --disable-java-agent-all \
        --disable-java-agent-jul --disable-java-agent-log4j \
        --disable-java-agent-log4j2 --disable-python-agent --disable-examples \
        --with-sdt=no
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
