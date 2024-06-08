/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2019-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Entry point to ROM stage 2
 * ------------------------------------------------------------
 */

#include <stddef.h>
#include <stdint.h>
#include <stdnoreturn.h>
#include <stdbool.h>
#include "load.h"
#include "machine.h"
#include "system.h"
#include "serial.h"
#include "rtlsupport.h"

extern void red_led_off();

// Linker defines
extern uint32_t _bss_start, _bss_end;
static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock * const)0x400;

// Flat binary kernels are loaded at the same address regardless of _how_ they're loaded
uint8_t *kernel_load_ptr = (uint8_t*) KERNEL_LOAD_ADDRESS;
KMain kernel_entry = (KMain) KERNEL_LOAD_ADDRESS;

#ifdef KERMIT_LOADER
// This is provided by Kermit
extern int receive_kernel();
#endif

void linit() {
    // zero .bss
    for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);
}

noreturn void lmain() {
    // Always do this for backwards compatibility
    ENABLE_RECV();

#ifndef MAME_FIRMWARE
#  if (defined SDFAT_LOADER) || (defined IDE_LOADER)
    FW_PRINT_C("Searching for boot media...\r\n");
#  endif

#  ifdef SDFAT_LOADER
    if (sd_load_kernel()) {
        goto have_kernel;
    }
#  endif
#  ifdef IDE_LOADER
    if (ide_load_kernel()) {
        goto have_kernel;
    }
#  endif
#  if (defined SDFAT_LOADER) || (defined IDE_LOADER)
    FW_PRINT_C("No bootable media found\r\n");
#  endif
#  ifdef KERMIT_LOADER
    FW_PRINT_C("Ready for Kermit receive...\r\n");

    BUSYWAIT_C(100000);

    while (!receive_kernel()) {
        FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Receive failed; Ready for retry...\r\n");
    }

    // Wait a short while for the user's terminal to come back...
    BUSYWAIT_C(400000);
    
    FW_PRINT_C("Kernel received okay; Starting...\r\n");
#  else
    FW_PRINT_C("No bootable media found & no Kermit support; Halting...\r\n");
    goto halt;
#  endif
#else
    FW_PRINT_C("Starting MAME Quickload kernel...\r\n");
#endif

#if !defined(MAME_FIRMWARE)
#  if defined SDFAT_LOADER || defined IDE_LOADER
have_kernel:
#  endif
#endif
    red_led_off();
    FW_PRINT_C("\r\n");

    kernel_entry(sdb);

    FW_PRINT_C("\x1b[1;31mSEVERE\x1b: Kernel should not return! Halting\r\n");

#ifndef KERMIT_LOADER
halt:
#endif
    while (true) {
        HALT();
    }
}
