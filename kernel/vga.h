// VGA driver header file

#ifndef VGA_H
#define VGA_H

#include <stdint.h>

// Function declarations
void vga_init(void);
void vga_clear(void);
void vga_print(const char *str);
void vga_putc(char c);

#endif
