# Not in the book: the newest upstream release, built with its Makefile as
# README.md says. It exists here for fwupd-efi, the UEFI program fwupd hands
# capsule updates to.
prepare() {
    # Upstream compiles with -Werror, so a warning new in this GCC would
    # fail the build.
    grep -q -- '-Wstrict-prototypes -Werror ' Make.defaults
    sed -i 's/-Wstrict-prototypes -Werror /-Wstrict-prototypes /' Make.defaults
    # Do not export SUBDIRS through make's command line: lib/Makefile has
    # its own architecture/runtime directory list, which must not be replaced.
    grep -q '^SUBDIRS    = lib inc apps$' Makefile
    sed -i 's/^SUBDIRS    = lib inc apps$/SUBDIRS    = lib inc/' Makefile
}

build() {
    # Only the library, the start-up code with its linker scripts, and the
    # headers: "apps" are upstream's example programs. The tarball's
    # Makefile still says 4.0.3, which would go into gnu-efi.pc. Upstream's
    # gnuefi: lib dependency orders those targets with parallel make.
    make -j"$JOBS" PREFIX=/usr LIBDIR=/usr/lib VERSION="$PKG_VERSION"
}

package() {
    # libefi.a, libgnuefi.a, crt0-efi-x86_64.o and the elf_x86_64*.lds
    # scripts in /usr/lib, the headers in /usr/include/efi, gnu-efi.pc. These
    # are static by nature: an EFI application cannot load shared libraries.
    make -j"$JOBS" PREFIX=/usr LIBDIR=/usr/lib VERSION="$PKG_VERSION" \
        INSTALLROOT="$DESTDIR" install
}
