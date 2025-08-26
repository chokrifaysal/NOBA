// ISR handler implementation in C
// Called from assembly with interrupt context

#include "vga.h"

// Array of exception messages
const char *exception_messages[] = {
    "Division by zero",
    "Debug",
    "Non-maskable interrupt",
    "Breakpoint",
    "Overflow",
    "Bound range exceeded",
    "Invalid opcode",
    "Device not available",
    "Double fault",
    "Coprocessor segment overrun",
    "Invalid TSS",
    "Segment not present",
    "Stack-segment fault",
    "General protection fault",
    "Page fault",
    "Reserved",
    "x87 floating-point exception",
    "Alignment check",
    "Machine check",
    "SIMD floating-point exception",
    "Virtualization exception",
    "Control protection exception",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved"
};

// Structure matching the stack layout after isr_common
struct interrupt_frame {
    uint32_t gs, fs, es, ds;
    uint32_t edi, esi, ebp, esp, ebx, edx, ecx, eax;
    uint32_t int_num, err_code;
    uint32_t eip, cs, eflags, user_esp, ss;
};

// Main ISR handler
void isr_handler(struct interrupt_frame *frame) {
    // Check if it's a known exception
    if (frame->int_num < 32) {
        vga_clear();
        vga_print("EXCEPTION: ");
        vga_print(exception_messages[frame->int_num]);
        vga_print("\nError code: ");
        
        // Convert error code to hex string
        char hex_buf[9];
        hex_buf[8] = '\0';
        for (int i = 7; i >= 0; i--) {
            int nibble = (frame->err_code >> (i * 4)) & 0xF;
            hex_buf[7 - i] = nibble < 10 ? '0' + nibble : 'A' + nibble - 10;
        }
        vga_print(hex_buf);
        
        // Halt on exception
        asm volatile ("cli; hlt");
    }
}

// Test function to trigger division by zero
void test_divide_by_zero(void) {
    asm volatile (
        "mov $0, %eax\n\t"
        "div %eax\n\t"  // This will cause division by zero
    );
}
