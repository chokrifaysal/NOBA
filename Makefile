# NOBA OS Makefile - with kernel building
# Supports building bootloader, kernel, and creating disk image

ASM = nasm
ASMFLAGS = -f bin

BOOT_SRC = boot/boot.asm
BOOT_BIN = build/boot.bin
KERNEL_SRC = kernel/kernel.asm
KERNEL_BIN = build/kernel.bin
DISK_IMG = build/noba.img

.PHONY: all clean run

all: $(DISK_IMG)

$(DISK_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$(BOOT_BIN) of=$@ conv=notrunc
	dd if=$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc

$(BOOT_BIN): $(BOOT_SRC)
	mkdir -p build
	$(ASM) $(ASMFLAGS) $< -o $@

$(KERNEL_BIN): $(KERNEL_SRC) kernel/vga.asm
	mkdir -p build
	$(ASM) $(ASMFLAGS) $< -o $@

clean:
	rm -rf build

run: $(DISK_IMG)
	qemu-system-x86_64 -drive format=raw,file=$(DISK_IMG) -monitor stdio

bochs: $(DISK_IMG)
	bochs -q -f bochsrc.txt
