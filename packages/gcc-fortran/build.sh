# Not a page of the book: LFS builds GCC for C and C++, and Beyond LFS's GCC
# page rebuilds the whole compiler with more languages. Here GCC is built
# again, configured exactly as the gcc package with Fortran added, and only
# what Fortran adds is packaged: the gfortran driver, the f951 compiler
# proper, libgfortran and the Fortran module files of libgfortran and
# libgomp. That is how other distributions split gcc-fortran from one GCC
# build (the make targets are the ones Arch Linux's gcc package uses).
prepare() {
    # Keep 64-bit libraries in /usr/lib instead of /usr/lib64, as gcc does.
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
}

build() {
    mkdir build
    cd build
    ../configure --prefix=/usr \
        LD=ld \
        --enable-languages=c,c++,fortran \
        --enable-default-pie \
        --enable-default-ssp \
        --enable-host-pie \
        --enable-targets=all \
        --disable-multilib \
        --disable-bootstrap \
        --disable-fixincludes \
        --with-system-zlib
    make
}

package() {
    cd build
    local target version
    target=$(gcc/xgcc -dumpmachine)
    version=$(cat ../gcc/BASE-VER)
    make -C "$target/libgfortran" DESTDIR="$DESTDIR" \
        install-cafexeclibLTLIBRARIES install-toolexeclibLTLIBRARIES \
        install-toolexeclibDATA install-nodist_fincludeHEADERS install-gfor_cHEADERS
    make -C "$target/libgomp" DESTDIR="$DESTDIR" install-nodist_fincludeHEADERS
    make -C gcc DESTDIR="$DESTDIR" fortran.install-common fortran.install-man fortran.install-info
    install -Dm755 gcc/f951 "$DESTDIR/usr/libexec/gcc/$target/$version/f951"
    # f95 is the traditional name of the Fortran 95 compiler.
    ln -s gfortran "$DESTDIR/usr/bin/f95"
}
