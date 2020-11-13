arch ?= x86_64
kernel_version := 5.9.8
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso
grub_cfg := src/arch/$(arch)/grub.cfg

all: usage

usage:
	echo "Usage here"

clean:
	rm -rf cache

download.kernel:
	mkdir -p cache
	curl --output cache/linux-$(kernel_version).tar.xz https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$(kernel_version).tar.xz 

make.kernel: download.kernel
	cd cache
	mkdir kbuild && cd kbuild
	xz -cd linux-$(kernel_version).tar.xz | tar xvf -

$(iso): make.kernel $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	@rm -r build/isofiles

run: $(iso)
	qemu-system-x86_64 -drive format=raw,file=kernel.bin -D ./log.txt

.PHONY: all usage download run clean

.SILENT: