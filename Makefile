.PHONY: lb_config lb_build clean distclean help

BUILD_LOG := build.log

GENERAL_BUILD_OPTIONS = \
	--apt-indices none \
	--apt-secure false \
	--apt-source-archives false \
	--archive-areas 'main contrib non-free' \
	--bootappend-live "boot=live config hostname=rabian username=rock" \
	--bootstrap-flavour minimal \
	--cache-stages false \
	--compression gzip \
	--distribution jessie \
	--gzip-options '-9 --rsyncable' \
	--mode debian \
	--security false

BUILD_OPTIONS = \
	--architectures armhf \
	--bootstrap debootstrap \
	--bootstrap-qemu-arch armhf \
	--bootstrap-qemu-static /usr/bin/qemu-arm-static \
	--firmware-binary false \
	--firmware-chroot false

all: lb_config lb_build

lb_config:
	[ -e DEBIAN ] || mkdir DEBIAN
	cd DEBIAN && \
	env LB_BOOTSTRAP_INCLUDE="apt-transport-https gnupg" \
		lb config $(GENERAL_BUILD_OPTIONS) \
			$(BUILD_OPTIONS)

	cp -f config/archives/* DEBIAN/config/archives
	cp -Rf config/includes.chroot/* DEBIAN/config/includes.chroot
	cp -f config/hooks/* DEBIAN/config/hooks
	cp -f config/package-lists/* DEBIAN/config/package-lists
	cp -f config/bootstrap DEBIAN/config
	cp -f config/chroot DEBIAN/config

lb_build:
	( cd DEBIAN && sudo lb build ) 2>&1 | tee $(BUILD_LOG)
	cp -f DEBIAN/binary/live/filesystem.ext4 ./rootfs.ext4

	rm -fr chroot/root/.bash_history
	rm -fr chroot/var/log/*
	rm -fr chroot/var/cache/apt/archives/*
	rm -fr chroot/tmp/*
	echo -e "\033[31mrootfs.ext4 in $(CURDIR)/rootfs.ext4\033[0m" 1>&2

clean:
	rm -f build.log rootfs.ext4
	rm -f DEBIAN/config/binary \
	DEBIAN/config/bootstrap \
	DEBIAN/config/chroot \
	DEBIAN/config/common \
	DEBIAN/config/source

distclean:
	rm -f build.log rootfs.ext4
	rm -rf DEBIAN

help:
	@echo " ------------------------------------------	"
	@echo "			radxa live build					"
	@echo " ------------------------------------------	"
	@echo " Build a custom live Debian.					"
	@echo " Usage:"
	@echo " make			- generate rootfs.ext4		"
	@echo " make help		- get more info				"
	@echo " make clean		- delete some build files	"
	@echo " make distclean	- recover to original state	"
