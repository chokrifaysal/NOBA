; Interrupt Descriptor Table setup for NOBA OS
; Handles CPU exceptions and hardware interrupts

; IDT entry structure
struc idt_entry
    .base_low:  resw 1
    .selector:  resw 1
    .zero:      resb 1
    .flags:     resb 1
    .base_high: resw 1
endstruc

; IDT with 256 entries
section .data
align 16
idt:
    times 256 dq 0

idt_descriptor:
    dw (256 * 8) - 1   ; Size of IDT
    dd idt             ; Address of IDT

; Exception handler stubs - macro to create ISR without error code
%macro isr_noerr 1
global isr%1
isr%1:
    cli
    push byte 0        ; Push dummy error code
    push byte %1       ; Push interrupt number
    jmp isr_common
%endmacro

; Exception handler stubs - macro to create ISR with error code
%macro isr_err 1
global isr%1
isr%1:
    cli
    push byte %1       ; Push interrupt number
    jmp isr_common
%endmacro

; Create ISRs for all 32 CPU exceptions
isr_noerr 0   ; Division by zero
isr_noerr 1   ; Debug
isr_noerr 2   ; Non-maskable interrupt
isr_noerr 3   ; Breakpoint
isr_noerr 4   ; Overflow
isr_noerr 5   ; Bound range exceeded
isr_noerr 6   ; Invalid opcode
isr_noerr 7   ; Device not available
isr_err   8   ; Double fault
isr_noerr 9   ; Coprocessor segment overrun
isr_err   10  ; Invalid TSS
isr_err   11  ; Segment not present
isr_err   12  ; Stack-segment fault
isr_err   13  ; General protection fault
isr_err   14  ; Page fault
isr_noerr 15  ; Reserved
isr_noerr 16  ; x87 floating-point exception
isr_err   17  ; Alignment check
isr_noerr 18  ; Machine check
isr_noerr 19  ; SIMD floating-point exception
isr_noerr 20  ; Virtualization exception
isr_noerr 21  ; Control protection exception
isr_noerr 22 ; Reserved
isr_noerr 23 ; Reserved
isr_noerr 24 ; Reserved
isr_noerr 25 ; Reserved
isr_noerr 26 ; Reserved
isr_noerr 27 ; Reserved
isr_noerr 28 ; Reserved
isr_noerr 29 ; Reserved
isr_noerr 30 ; Reserved
isr_noerr 31 ; Reserved

; Common ISR handler that saves all registers
extern isr_handler
isr_common:
    ; Save all registers
    pusha
    push ds
    push es
    push fs
    push gs
    
    ; Load kernel data segment
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; Call C handler
    push esp
    call isr_handler
    add esp, 4
    
    ; Restore registers
    pop gs
    pop fs
    pop es
    pop ds
    popa
    
    ; Clean up error code and interrupt number
    add esp, 8
    
    ; Return from interrupt
    iret

; Load IDT
global idt_load
idt_load:
    lidt [idt_descriptor]
    ret

; Set an IDT entry
; edi = IDT index, eax = handler address, ebx = flags
global idt_set_entry
idt_set_entry:
    push edi
    push eax
    push ebx
    
    ; Calculate IDT entry address
    mov edi, idt
    add edi, [esp + 16]  ; Get index parameter
    imul edi, 8
    
    ; Set base low and high
    mov [edi + idt_entry.base_low], ax
    shr eax, 16
    mov [edi + idt_entry.base_high], ax
    
    ; Set selector (kernel code segment)
    mov word [edi + idt_entry.selector], 0x08
    
    ; Set zero byte
    mov byte [edi + idt_entry.zero], 0
    
    ; Set flags
    mov al, [esp + 12]  ; Get flags parameter
    mov [edi + idt_entry.flags], al
    
    pop ebx
    pop eax
    pop edi
    ret
