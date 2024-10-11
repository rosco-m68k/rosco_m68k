/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2020 Xark
 * MIT License
 *
 * Example SD card file menu
 * ------------------------------------------------------------
 */

#include <ctype.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>

#include <rosco_m68k/machine.h>

// number of elements in C array
#define ELEMENTS(a) ((int)(sizeof(a) / sizeof(*a)))

// main SD Card Menu function
extern void sdboot_menu();

// Use custom __kinit (called by serial_start init.S before kmain) to set private stack area and call main
static unsigned int private_stack[4096]; // 16KB "private" stack

int main(void)
{
    __asm__ __volatile__(" move.l %[private_stack],%%sp\n"
                         " move.l  4.w,-(%%sp)"
                         :
                         : [private_stack] "a"(&private_stack[ELEMENTS(private_stack) - 1])
                         :);
    sdboot_menu();      // call kmain here
    _WARM_BOOT(); // since returning with new stack would be "bad"
}
