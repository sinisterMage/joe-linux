# Not in the book: the newest upstream release, built with its Makefile as
# its README says. The Makefile turns on journald logging and seccomp
# notification itself when libsystemd and libseccomp are present.
build() {
    # Upstream's CFLAGS without -Werror, so that a warning new in this
    # compiler does not stop the build.
    make PREFIX=/usr CFLAGS="-std=c99 -Os -Wall -Wextra"
    # The manual page, from Markdown.
    make -C docs PREFIX=/usr
}

package() {
    # /usr/bin/conmon is where Podman (containers.conf) looks first after
    # its own libexec directory.
    make PREFIX=/usr DESTDIR="$DESTDIR" install.bin
    make -C docs PREFIX=/usr DESTDIR="$DESTDIR" install
}
