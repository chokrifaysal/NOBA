; NOBA OS Kernel - 16-bit portion
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

    ; Load GDT and switch to protected mode
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1        ; Set protected mode bit
    mov cr0, eax

    ; Far jump to 32-bit code segment
    jmp CODE_SEG:protected_mode_start

; Print null-terminated string (16-bit real mode)
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

; GDT definition
gdt_start:
    ; Null descriptor
    dq 0

gdt_code:
    ; Code segment descriptor
    dw 0xFFFF          ; Limit (0-15)
    dw 0x0000          ; Base (0-15)
    db 0x00            ; Base (16-23)
    db 10011010b       ; Access byte (present, ring 0, code segment, executable, readable)
    db 11001111b       ; Flags (granularity, 32-bit) + Limit (16-19)
    db 0x00            ; Base (24-31)

gdt_data:
    ; Data segment descriptor
    dw 0xFFFF          ; Limit (0-15)
    dw 0x0000          ; Base (0-15)
    db 0x00            ; Base (16-23)
    db 10010010b       ; Access byte (present, ring 0, data segment, writable)
    db 11001111b       ; Flags (granularity, 32-bit) + Limit (16-19)
    db 0x00            ; Base (24-31)

gdt_end:

; GDT descriptor
gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT
    dd gdt_start                ; Start address of GDT

; Constants
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Data
kernel_msg db "Kernel loaded, switching to protected mode...", 0xD, 0xA, 0

; 32-bit protected mode code
BITS 32

protected_mode_start:
    ; Set up segment registers for protected mode
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000   ; Set up stack pointer

    ; Call our main kernel function
    call kernel_main

    ; Halt if we return
    jmp $

; Include VGA driver
%include "kernel/vga.asm"

; Include IDT setup
%include "kernel/idt.asm"

; Kernel main function
kernel_main:
    ; Initialize VGA
    call vga_init
    
    ; Print welcome message
    mov esi, protected_msg
    call vga_print
    
    ; Initialize IDT
    call init_idt
    
    ; Load IDT
    call idt_load
    
    ; Test exception handling
    call test_exception
    
    ; Halt for now
    jmp $

init_idt:
    ; Set up exception handlers
    mov ebx, 0x8E      ; Present, ring 0, interrupt gate
    
    ; Set up first 32 entries (CPU exceptions)
    mov ecx, 0
.setup_loop:
    cmp ecx, 32
    jge .setup_done
    
    ; Calculate handler address
    mov eax, [isr_stubs + ecx * 4]
    
    ; Set IDT entry
    push ebx
    push eax
    push ecx
    call idt_set_entry
    add esp, 12
    
    inc ecx
    jmp .setup_loop
    
.setup_done:
    ret

test_exception:
    ; Test division by zero exception
    mov esi, test_msg
    call vga_print
    
    ; This will trigger a division by zero
    mov eax, 1
    mov ebx, 0
    div ebx
    
    ret

; Array of ISR stub addresses
isr_stubs:
    dd isr0, isr1, isr2, isr3, isr4, isr5, isr6, isr7
    dd isr8, isr9, isr10, isr11, isr12, isr13, isr14, isr15
    dd isr16, isr17, isr18, isr19, isr20, isr21, isr22, isr23
    dd isr24, isr25, isr26, isr27, isr28, isr29, isr30, isr31

protected_msg db "NOBA OS running in protected mode!", 0xA, 0
test_msg db "Testing exception handling...", 0xA, 0

; Pad kernel to multiple of 512 bytes
times 8192-($-kernel_start) db 0
