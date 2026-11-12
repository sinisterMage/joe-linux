# joe Linux: top-level build and test entry points.
#
# Everything here runs as an ordinary user. Nothing needs root on the host.

DAVE := dave/zig-out/bin/dave

.PHONY: help dave test test-cli scaffold test-boot-contract test-deployments \
        bootstrap packages image run test-joe clean

help:
	@echo "dave"
	@echo "  make dave                 build the package manager"
	@echo "  make test                 unit tests and command-line tests (seconds)"
	@echo ""
	@echo "deployment mechanics on a throwaway scaffold image (minutes, needs KVM)"
	@echo "  make test-boot-contract   what the design assumes about systemd-boot"
	@echo "  make test-deployments     upgrade, rollback, power loss, broken upgrade"
	@echo ""
	@echo "joe Linux from source (about an hour on a 32-core machine)"
	@echo "  make bootstrap            cross toolchain and temporary tools"
	@echo "  make packages             build every recipe into build/repo"
	@echo "  make image                bootable image at build/images/joe.img"
	@echo "  make run                  boot that image in QEMU on this terminal"
	@echo "  make test-joe             the deployment tests on that image"

$(DAVE): $(wildcard dave/src/*.zig dave/src/solver/*.zig) dave/build.zig
	cd dave && zig build -Doptimize=ReleaseSafe

dave: $(DAVE)

test: $(DAVE)
	cd dave && zig build test --summary all
	tests/cli.sh

build/host-tools/bin/mcopy:
	mkdir -p build/src build/host-tools
	cd build/src && curl -fsSLO https://ftp.gnu.org/gnu/mtools/mtools-4.0.49.tar.bz2
	cd build/src && rm -rf mtools && mkdir mtools && tar -xf mtools-4.0.49.tar.bz2 -C mtools --strip-components=1
	cd build/src/mtools && ./configure --prefix=$(CURDIR)/build/host-tools --disable-floppyd && $(MAKE) && $(MAKE) install

build/scaffold/archlinux-bootstrap.tar.zst:
	mkdir -p build/scaffold
	curl -fsSL -o $@ https://geo.mirror.pkgbuild.com/iso/latest/archlinux-bootstrap-x86_64.tar.zst

build/images/scaffold.img: build/scaffold/archlinux-bootstrap.tar.zst build/host-tools/bin/mcopy
	mkdir -p build/images
	image/mkscaffold.sh
	image/mkimage.sh --rootfs build/scaffold/rootfs \
	    --kernel /usr/lib/modules/$$(uname -r)/vmlinuz \
	    --sdboot /usr/lib/systemd/boot/efi/systemd-bootx64.efi \
	    --out $@ --cmdline "console=ttyS0,115200"

scaffold: build/images/scaffold.img

test-boot-contract: build/images/scaffold.img
	python3 tests/vm/smoke.py build/images/scaffold.img
	python3 tests/vm/boot_contract.py build/images/scaffold.img

test-deployments: build/images/scaffold.img $(DAVE)
	python3 tests/vm/deployments.py

build/lfs/wget-list:
	mkdir -p build/lfs build/src
	curl -fsSL -o build/lfs/wget-list https://www.linuxfromscratch.org/lfs/view/systemd/wget-list
	curl -fsSL -o build/lfs/md5sums https://www.linuxfromscratch.org/lfs/view/systemd/md5sums
	cd build/src && xargs -P 8 -n 1 curl -fsSL --retry 3 -O < ../lfs/wget-list
	cd build/src && md5sum -c --quiet ../lfs/md5sums

bootstrap: build/lfs/wget-list
	bootstrap/stage1.sh
	bootstrap/stage2.sh

packages: $(DAVE)
	bootstrap/build-packages.sh

# --test: root logs in on the serial console without a password. There is no
# installer yet to set one, so this is how a demonstration image is used.
image: build/host-tools/bin/mcopy
	mkdir -p build/images
	image/mkjoe.sh --test --repo joe,$(CURDIR)/build/repo,http://10.0.2.2:8643,$(CURDIR)/build/keys/joe.pub \
	    build/images/joe.img joe-base

run:
	image/run.sh

test-joe: build/host-tools/bin/mcopy $(DAVE)
	python3 tests/vm/deployments.py --joe

clean:
	rm -rf dave/.zig-cache dave/zig-out build/cli-test build/work
