/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2021 Xark
 * MIT License
 *
 * rosco_m68k "kernel main" for bare-metal programs
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <basicio.h>
#include <machine.h>

extern void main(int argc, char **argv);

void kmain()
{
    main(0, NULL);
}

// Use custom __kinit (called by serial_start init.S before kmain) to set
// private stack area and call main
// Workaround for #135.
extern unsigned int _data_start, _data_end, _code_end, _bss_start, _bss_end;
static unsigned int private_stack[1024];        // 4KB "private" stack

void __kinit()
{
    __asm__ __volatile__(
        " move.l %[private_stack],%%sp\n"
        :
        : [private_stack] "a"(&private_stack[(sizeof(private_stack)/sizeof(private_stack[0])) - 1])
        :);
    // zero .bss
    for (unsigned int * dst = &_bss_start; dst < &_bss_end; dst++)
    {
        *dst = 0;
    }
    kmain();             // call kmain here
    _WARM_BOOT();        // since returning with new stack would be "bad"
}
