# Not in the book: the newest upstream release, built as its README says.
# Besides passt and pasta this builds AVX2 variants of both, which they
# run instead when the processor has AVX2, passt-repair (TCP_REPAIR helper
# for migrating virtual machines) and pesto. The SELinux and AppArmor
# policies in contrib/ are not installed: joe has neither.
build() {
    # VERSION would otherwise be taken from git describe.
    make prefix=/usr VERSION="$PKG_VERSION"
}

package() {
    make prefix=/usr VERSION="$PKG_VERSION" DESTDIR="$DESTDIR" install
}
