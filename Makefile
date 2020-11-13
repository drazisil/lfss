arch ?= x86_64
kernel_version := 5.9.8
kernel_build_dir := cache/kbuild
kernel := $(kernel_build_dir)/linux-$(kernel_version)/arch/$(arch)/boot/bzImage
iso := build/os-$(arch).iso
grub_cfg := build/arch/$(arch)/grub.cfg
initd := build/arch/$(arch)/init
hda_img := build/myimage.img

all: usage

usage:
	echo "Usage here"

clean:
	rm -rf cache

# This should be turned into a ./configure script
requirements: clean
	sudo apt install \
		flex

download.kernel: requirements
	mkdir -p cache
	curl --output cache/linux-$(kernel_version).tar.xz https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$(kernel_version).tar.xz 

make.kernel: download.kernel
	mkdir -p $(kernel_build_dir) && cd $(kernel_build_dir) && \
	xz -cd ../linux-$(kernel_version).tar.xz | tar xvf - && \
	cd linux-$(kernel_version) && \
	make defconfig && \
	echo "Building kernel..." && \
	make V=1 all

$(iso): $(kernel) $(grub_cfg)
	mkdir -p build/isofiles/boot/grub
	mkdir -p build/isofiles/bin
	cp $(kernel) build/isofiles/boot/vmlinux
	cp $(grub_cfg) build/isofiles/boot/grub
	# $(kernel_build_dir)/linux-$(kernel_version)/tools/testing/selftests/rcutorture/bin/mkinitrd.sh build/isofiles/bootinitrd-latest.img $(kernel_version)-$(arch)
	#-- TODO: Make the initrd image for the correct kernel version.
	cp build/arch/x86_64/initrd.img-4.19.0-12-amd64 build/isofiles/boot
	grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	rm -r build/isofiles

run: $(iso)
	qemu-img create -f raw $(hda_img) 8G
	# sudo parted $(hda_img) mktable gpt					# Create a gpt partition table
	# sudo parted $(hda_img) mkpart primary ext4 1MB 7MB  # Create a 7MB primary partition
	sudo mkfs.ext4 $(hda_img)
	qemu-system-x86_64 -cdrom $(iso) -m 4G -serial file:./log.txt -boot d $(hda_img) 

.PHONY: all usage download run clean

.SILENT: