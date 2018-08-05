CFLAGS			?= -O2 -g
# switch output modes: dir (outputs into directory at bin/hdd/), cd (build an ISO image) or fat (creates a FAT32 image at bin/hdd.img)
MODE			?= dir

OBJ				:= kernel/kernel.o
DEP				:= $(addprefix .deps/,$(OBJ:.o=.d))
KERNEL			:= bin/hdd/efi/boot/bootx64.efi
HDD				:= bin/hdd.img
CD				:= bin/cd.iso

ifndef USE_GCC
	CC			:= clang
	LD			:= lld-link-6.0
	CFLAGS		:= $(CFLAGS) -flto -fpic -target x86_64-pc-win32-coff
	LDFLAGS		:= -subsystem:efi_application -nodefaultlib -dll -WX -entry:efi_main -out:$(KERNEL)
else
	CC			:= x86_64-w64-mingw32-gcc
	LD			:= x86_64-w64-mingw32-gcc
	CFLAGS		:= $(CFLAGS)
	LDFLAGS		:= -nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e efi_main -o $(KERNEL)
endif

EMU				:= qemu-system-x86_64

CFLAGS			+= -ffreestanding -fno-stack-protector -fshort-wchar -Ikernel/include -MMD -MP -mno-red-zone -std=c11 -Wall -Wextra
EMUFLAGS		:= -drive if=pflash,format=raw,file=bin/OVMF.fd -M accel=kvm:tcg -net none -serial stdio

ifeq ($(MODE),fat)
	EMUFLAGS	+= -drive if=ide,format=raw,file=$(HDD)
	EMU_REQ		:= $(HDD)
else ifeq ($(MODE),dir)
	EMUFLAGS	+= -drive format=raw,file=fat:rw:bin/hdd
	EMU_REQ		:=
else ifeq ($(MODE),cd)
	EMUFLAGS	+= -cdrom $(CD)
	EMU_REQ		+= $(CD)
else
	$(error)
endif

OVMF_URL		:= https://dl.bintray.com/no92/vineyard-binary/OVMF.fd
OVMF_BIN		:= OVMF.fd
OVMF			:= bin/$(OVMF_BIN)

kernel: $(KERNEL) ## build the kernel
hdd: $(HDD) ## build a bootable FAT32 image

prepare: kernel/include/efi

kernel/include/efi:
	jiri init
	jiri update

$(KERNEL): $(OBJ)
	mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) $<
	rm -f $(KERNEL:.efi=.lib)

%.o: %.c
	mkdir -p $(dir .deps/$(@:.o=.d))
	$(CC) $(CFLAGS) -c $< -o $@ -MF .deps/$(@:.o=.d)

$(HDD): $(KERNEL)
	dd if=/dev/zero of=$(HDD) bs=1k count=1440
	mformat -i $(HDD) -f 1440 ::
	mmd -i $(HDD) ::/EFI
	mmd -i $(HDD) ::/EFI/BOOT
	mcopy -i $(HDD) $(KERNEL) ::/EFI/BOOT/BOOTX64.EFI

$(CD): $(HDD)
	mkdir -p iso
	cp $(HDD) iso
	xorriso -as mkisofs -R -f -e $(shell basename $(HDD)) -no-emul-boot -o $(CD) iso

test: $(KERNEL) $(OVMF) $(EMU_REQ) ## run the kernel in QEMU
	$(EMU) $(EMUFLAGS)

$(OVMF):
	mkdir -p bin
	wget $(OVMF_URL) -O $(OVMF) -qq

clean: ## clean build files
	rm -f $(KERNEL)
	rm -f $(OBJ) $(DEP)

clean-bin: clean
	rm -rf $(HDD) $(CD) iso

clean-ovmf:
	rm -f $(OVMF)

clean-zircon-efi:
	rm -rf kernel/include/efi

distclean: clean clean-bin clean-ovmf clean-zircon-efi ## clean everything
	rm -rf .jiri_root bin

-include $(DEP)

.DEFAULT_GOAL := help
help: ## display this help
	@echo "$$(tput bold)Available targets:$$(tput sgr0)"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

.PHONY: kernel hdd test clean clean-bin clean-ovmf clean-zircon-efi help

.SUFFIXES:
.SUFFIXES: .c .o
