.PHONY: lb_config lb_build clean distclean help
.PHONY: rock rock_pro rock_lite rock2_square rock_sdcard rock_pro_sdcard

BUILD_LOG := live-build.log
GIT_REV=$(shell git rev-parse --short HEAD)

GENERAL_BUILD_OPTIONS = \
	--apt apt \
	--apt-indices none \
	--apt-secure false \
	--apt-source-archives false \
	--archive-areas 'main contrib non-free' \
	--bootappend-live "boot=live config hostname=rock username=rock" \
	--bootstrap-flavour minimal \
	--cache true \
	--cache-indices true \
	--cache-packages true \
	--cache-stages bootstrap \
	--checksums md5 \
	--compression gzip \
	--distribution jessie \
	--gzip-options '-9 --rsyncable' \
	--mode debian \
	--security false

FILESYSTEM_OPTIONS = \
	--binary-filesystem ext4 \
	--chroot-filesystem ext4 \
	--binary-images tar \
	--initramfs live-boot \
	--system live \
	--initsystem systemd

BUILD_OPTIONS = \
	--architectures armhf \
	--bootstrap debootstrap \
	--bootstrap-qemu-arch armhf \
	--bootstrap-qemu-static /usr/bin/qemu-arm-static \
	--firmware-binary false \
	--firmware-chroot falsall: lb_config lb_build

rock rock_pro rock_lite rock2_square rock_sdcard rock_pro_sdcard:
	@rm -f config
	@cp -rf $@/* common_config
	@ln -sf common_config config
	@if [ ! -e DEBIAN/ ]; then mkdir DEBIAN; fi;
	@cd DEBIAN && \
	env LB_BOOTSTRAP_INCLUDE="apt-transport-https gnupg" \
		lb config $(GENERAL_BUILD_OPTIONS) \
			$(FILESYSTEM_OPTIONS) \
			$(BUILD_OPTIONS)

	@echo "I: copy customization"
	@cp -f config/archives/* DEBIAN/config/archives
	@cp -Rf config/includes.chroot/* DEBIAN/config/includes.chroot
	@cp -f config/hooks/* DEBIAN/config/hooks
	@cp -f config/package-lists/* DEBIAN/config/package-lists
	@cp -f config/bootstrap DEBIAN/config
	@cp -f config/chroot DEBIAN/config

	( cd DEBIAN && sudo lb build ) 2>&1 | tee $(BUILD_LOG)
	@cp -f DEBIAN/binary/live/filesystem.ext4 ./rabian_$@.ext4

	@rm -fr chroot/root/.bash_history
	@rm -fr chroot/var/log/*
	@rm -fr chroot/var/cache/apt/archives/*
	@rm -fr chroot/tmp/*
	@echo -e "\033[31mrootfs.ext4 in $(CURDIR)/rabian_$@_$(GIT_REV).ext4\033[0m" 1>&2

usage:
	@echo "make: *** [usage] choice the target board!"

clean:
	@if [ -e DEBIAN/ ]; then cd DEBIAN/ && sudo lb clean; fi;
	@rm -f $(BUILD_LOG) rootfs_*.ext4
	@rm -rf DEBIAN/config config
	@rm -rf common_config
	@git checkout -f common_config

distclean:
	@if [ -e DEBIAN/ ]; then cd DEBIAN/ && sudo lb clean; fi;
	@rm -f $(BUILD_LOG) rabian_*.ext4
	@rm -rf DEBIAN
	@rm -rf config
	@rm -rf common_config
	@git checkout -f common_config

help:
	@echo " ------------------------------------------	"
	@echo "			radxa live build		"
	@echo " ------------------------------------------	"
	@echo " Build a custom live Debian.			"
	@echo " Usage:"
	@echo " make			- generate rootfs.ext4	"
	@echo " make help		- get more info		"
	@echo " make clean		- delete build files	"
	@echo " make distclean	- recover to original state	"
