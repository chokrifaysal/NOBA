; NOBA OS Bootloader - BIOS version with disk loading
; Written in NASM syntax, Intel style
; Loads kernel stub from disk and jumps to it

BITS 16
ORG 0x7C00

; BPB (BIOS Parameter Block)
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
    ; Set up segment registers
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Save boot drive
    mov [boot_drive], dl

    ; Print boot message
    mov si, boot_msg
    call print_string

    ; Load kernel stub from disk
    mov bx, KERNEL_LOAD_SEGMENT
    mov es, bx
    mov bx, KERNEL_LOAD_OFFSET
    mov dh, 4          ; Number of sectors to read (kernel stub size)
    mov dl, [boot_drive]
    mov ch, 0          ; Cylinder 0
    mov cl, 2          ; Start from sector 2 (after boot sector)
    call disk_load

    ; Jump to loaded kernel
    jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET

; Disk load function
; ES:BX = buffer to load to
; DH = number of sectors to read
; DL = drive number
; CH = cylinder number
; CL = sector number
disk_load:
    pusha
    mov di, 3          ; Retry count
.retry:
    pusha
    mov ah, 0x02       ; BIOS read sector function
    mov al, dh         ; Number of sectors to read
    mov dh, 0          ; Head number
    int 0x13
    jnc .success       ; If no error, success

    ; Error handling
    popa
    dec di
    jz .error          ; If retries exhausted, error

    ; Reset disk system
    pusha
    xor ah, ah
    int 0x13
    popa
    jmp .retry

.error:
    mov si, disk_error_msg
    call print_string
    jmp $              ; Halt on error

.success:
    popa
    popa
    ret

; Print null-terminated string
; DS:SI = string address
print_string:
    pusha
    mov ah, 0x0E
.print_char:
    lodsb
    test al, al
    jz .print_done
    int 0x10
    jmp .print_char
.print_done:
    popa
    ret

; Constants
KERNEL_LOAD_SEGMENT equ 0x1000
KERNEL_LOAD_OFFSET equ 0x0000

; Data
boot_msg db "NOBA bootloader starting...", 0xD, 0xA, 0
disk_error_msg db "Disk read error!", 0xD, 0xA, 0
boot_drive db 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
