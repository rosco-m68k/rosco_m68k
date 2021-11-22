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

#include <basicio.h>
#include <machine.h>
#include <sdfat.h>

// number of elements in C array
#define ELEMENTS(a) ((int)(sizeof(a) / sizeof(*a)))

// main SD Card Menu function
extern void sdfat_menu();

void kmain()
{
    sdfat_menu();
}

// Use custom __kinit (called by serial_start init.S before kmain) to set private stack area and call main
extern unsigned int _data_start, _data_end, _code_end, _bss_start, _bss_end;
static unsigned int private_stack[4096]; // 16KB "private" stack

void __kinit()
{
    __asm__ __volatile__(" move.l %[private_stack],%%sp\n"
                         " move.l  4.w,-(%%sp)"
                         :
                         : [private_stack] "a"(&private_stack[ELEMENTS(private_stack) - 1])
                         :);
    // zero .bss
    for (unsigned int * dst = &_bss_start; dst < &_bss_end; dst++)
    {
        *dst = 0;
    }
    kmain();      // call kmain here
    _WARM_BOOT(); // since returning with new stack would be "bad"
}
