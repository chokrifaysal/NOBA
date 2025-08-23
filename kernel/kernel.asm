; NOBA OS Kernel Stub
; Loaded at 0x1000:0x0000 by bootloader

BITS 16

kernel_start:
    ; Set up segment registers
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFF0     ; Stack at top of segment

    ; Print kernel message
    mov si, kernel_msg
    call print_string

    ; Halt ()
    jmp $

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

kernel_msg db "Kernel loaded successfully!", 0xD, 0xA, 0

; Pad kernel to multiple of 512 bytes
times 2048-($-kernel_start) db 0
