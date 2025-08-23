# NOBA OS Makefile - initial version
# Supports building bootloader and creating disk image

ASM = nasm
ASMFLAGS = -f bin

BOOT_SRC = boot/boot.asm
BOOT_BIN = build/boot.bin
DISK_IMG = build/noba.img

.PHONY: all clean run

all: $(DISK_IMG)

$(DISK_IMG): $(BOOT_BIN)
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$< of=$@ conv=notrunc

$(BOOT_BIN): $(BOOT_SRC)
	mkdir -p build
	$(ASM) $(ASMFLAGS) $< -o $@

clean:
	rm -rf build

run: $(DISK_IMG)
	qemu-system-x86_64 -drive format=raw,file=$(DISK_IMG) -monitor stdio

# For bochs emulator
bochs: $(DISK_IMG)
	bochs -q -f bochsrc.txt
