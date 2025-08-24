# NOBA OS Makefile - with kernel building
# Supports building bootloader, kernel, and creating disk image

ASM = nasm
ASMFLAGS = -f elf32
CC = gcc
CFLAGS = -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector -Wall -Wextra -I./kernel

BOOT_SRC = boot/boot.asm
BOOT_BIN = build/boot.bin
KERNEL_SRC = kernel/kernel.asm
KERNEL_OBJ = build/kernel.o
ISR_OBJ = build/isr.o
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

$(KERNEL_BIN): $(KERNEL_OBJ) $(ISR_OBJ)
	ld -m elf_i386 -Ttext 0x10000 -o build/kernel.elf $(KERNEL_OBJ) $(ISR_OBJ)
	objcopy -O binary build/kernel.elf $@

$(KERNEL_OBJ): $(KERNEL_SRC) kernel/vga.asm kernel/idt.asm
	mkdir -p build
	$(ASM) $(ASMFLAGS) $< -o $@

$(ISR_OBJ): kernel/isr.c kernel/vga.h
	mkdir -p build
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf build

run: $(DISK_IMG)
	qemu-system-x86_64 -drive format=raw,file=$(DISK_IMG) -monitor stdio

bochs: $(DISK_IMG)
	bochs -q -f bochsrc.txt
