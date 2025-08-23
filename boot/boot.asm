; NOBA OS Bootloader - BIOS version
; Written in NASM syntax, Intel style
; Loaded at 0x7C00 by BIOS

BITS 16
ORG 0x7C00

; BPB (BIOS Parameter Block) - some BIOSes require this
bpb:
    jmp short boot_start
    nop
    times 8 db 0
    dw 512             ; Bytes per sector
    db 1               ; Sectors per cluster
    dw 1               ; Reserved sectors
    db 2               ; FAT copies
    dw 224             ; Root directory entries
    dw 2880            ; Total sectors
    db 0xF0            ; Media descriptor
    dw 9               ; Sectors per FAT
    dw 18              ; Sectors per track
    dw 2               ; Number of heads
    dd 0               ; Hidden sectors
    dd 0               ; Large sector count

; Extended BPB
    db 0x80            ; Drive number
    db 0               ; Reserved
    db 0x29            ; Boot signature
    dd 0xDEADBEEF      ; Volume serial number
    db "NOBA OS    "   ; Volume label
    db "FAT12   "      ; File system type

boot_start:
    ; Set up segment registers to known state
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00     ; Stack grows downward from bootloader
    sti

    ; Save boot drive number
    mov [boot_drive], dl

    ; Print boot message
    mov si, boot_msg
    call print_string

    ; Halt until we implement disk loading
    jmp $

; Print null-terminated string
; DS:SI = string address
print_string:
    pusha
    mov ah, 0x0E       ; BIOS teletype function
.print_char:
    lodsb
    test al, al
    jz .print_done
    int 0x10
    jmp .print_char
.print_done:
    popa
    ret

; Data section
boot_msg db "NOBA bootloader starting...", 0xD, 0xA, 0
boot_drive db 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
