/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2019 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Entry point to ROM stage 2
 * ------------------------------------------------------------
 */

#include <stddef.h>
#include <stdint.h>
#include <stdnoreturn.h>
#include <stdbool.h>
#include "machine.h"
#include "system.h"
#include "serial.h"
#include "rtlsupport.h"

extern void mcPrint(char *str);
extern void mcBusywait(uint32_t nops);
extern void mcHalt();
extern void ENABLE_RECV();
//extern void INIT_SYSCALLS();

/*
 * This is what a Kernel entry point should look like.
 */
typedef void (*KMain)(volatile SystemDataBlock * const);

// Linker defines
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end;

static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock * const)0x400;

// Kernels are loaded at the same address regardless of _how_ they're loaded
uint8_t *kernel_load_ptr = (uint8_t*) KERNEL_LOAD_ADDRESS;
static KMain kmain = (KMain) KERNEL_LOAD_ADDRESS;

// This is provided by Kermit
extern int receive_kernel();

void linit() {
    // zero .bss
    for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);
}

noreturn void lmain() {
    // Take over from stage one's syscalls...
    //INIT_SYSCALLS();

    // Always do this for backwards compatibility
    ENABLE_RECV();

    mcPrint("Ready for Kermit receive...\r\n");

#ifndef MAME_FIRMWARE
    while (!receive_kernel()) {
        mcPrint("\x1b[1;31mSEVERE\x1b[0m: Receive failed; Ready for retry...\r\n");
    }

    // Wait a short while for the user's terminal to come back...
    mcBusywait(100000);
#endif

    mcPrint("Kernel received okay; Starting...\r\n");

    kmain(sdb);

    mcPrint("\x1b[1;31mSEVERE\x1b: Kernel should not return! Halting\r\n");

    while (true) {
        mcHalt();
    }
}
