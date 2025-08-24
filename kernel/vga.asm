; VGA text mode driver for protected mode
; Uses 0xB8000 as video memory address

; VGA constants
VGA_MEMORY equ 0xB8000
VGA_WIDTH equ 80
VGA_HEIGHT equ 25

; Current cursor position
vga_x: dd 0
vga_y: dd 0
vga_color: db 0x0F  ; White on black

; Initialize VGA driver
vga_init:
    pusha
    mov dword [vga_x], 0
    mov dword [vga_y], 0
    mov byte [vga_color], 0x0F
    call vga_clear
    popa
    ret

; Clear the screen
vga_clear:
    pusha
    mov edi, VGA_MEMORY
    mov ecx, VGA_WIDTH * VGA_HEIGHT
    mov ah, [vga_color]
    mov al, ' '
.clear_loop:
    mov [edi], ax
    add edi, 2
    loop .clear_loop
    mov dword [vga_x], 0
    mov dword [vga_y], 0
    popa
    ret

; Print a null-terminated string
; ESI = string address
vga_print:
    pusha
.print_loop:
    mov al, [esi]
    test al, al
    jz .print_done
    call vga_putc
    inc esi
    jmp .print_loop
.print_done:
    popa
    ret

; Print a character
; AL = character to print
vga_putc:
    pusha
    
    ; Handle newline
    cmp al, 0x0A
    jne .not_newline
    mov dword [vga_x], 0
    inc dword [vga_y]
    jmp .check_scroll
    
.not_newline:
    ; Calculate memory offset
    mov ebx, [vga_y]
    imul ebx, VGA_WIDTH * 2
    mov ecx, [vga_x]
    imul ecx, 2
    add ebx, ecx
    add ebx, VGA_MEMORY
    
    ; Write character and attribute
    mov ah, [vga_color]
    mov [ebx], ax
    
    ; Advance cursor
    inc dword [vga_x]
    
.check_scroll:
    ; Check if we need to scroll
    mov eax, [vga_x]
    cmp eax, VGA_WIDTH
    jl .no_scroll
    mov dword [vga_x], 0
    inc dword [vga_y]
    
.no_scroll:
    mov eax, [vga_y]
    cmp eax, VGA_HEIGHT
    jl .done
    call vga_scroll
    
.done:
    popa
    ret

; Scroll the screen up by one line
vga_scroll:
    pusha
    mov esi, VGA_MEMORY + (VGA_WIDTH * 2)
    mov edi, VGA_MEMORY
    mov ecx, VGA_WIDTH * (VGA_HEIGHT - 1)
.scroll_loop:
    movsw
    loop .scroll_loop
    
    ; Clear the last line
    mov edi, VGA_MEMORY + (VGA_WIDTH * 2 * (VGA_HEIGHT - 1))
    mov ecx, VGA_WIDTH
    mov ah, [vga_color]
    mov al, ' '
.clear_last:
    mov [edi], ax
    add edi, 2
    loop .clear_last
    
    ; Set cursor to beginning of last line
    mov dword [vga_y], VGA_HEIGHT - 1
    mov dword [vga_x], 0
    
    popa
    ret
