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
 * This is the entry point for the Kernel.
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

#ifdef EASY68K_TRAP
extern void INSTALL_EASY68K_TRAP_HANDLERS();
#endif

/*
 * This is what a Kernel entry point should look like.
 */
typedef void (*KMain)(SystemDataBlock * const);

// Linker defines
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end;

static SystemDataBlock * const sdb = (SystemDataBlock * const)0x400;

// Load the kernel at the end of this loader's data section.
// Once the kernel is running it's free to relocate or reuse the loader's memory.
// Memory from 0x1000 is guaranteed to be reusable once the loader is done.
//
// This does mean where the kernel is loaded will vary depending on which loader
// is used, so use PIC, at least for the bit that relocates your kernel!
//
uint8_t *kernel_load_ptr = (uint8_t*) 0x28000;
static KMain kmain = (KMain) 0x28000;

int receive_kernel();

void linit() {
  // copy .data
  for (uint32_t *dst = &_data_start, *src = &_code_end; dst < &_data_end; *dst = *src, dst++, src++);

  // zero .bss
  for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);
}

noreturn void lmain() {
    if (sdb->magic != 0xB105D47A) {
        EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: SDB Magic mismatch; SDB is trashed. Halting.\r\n");
        HALT();
    }

#ifdef EASY68K_TRAP
    INSTALL_EASY68K_TRAP_HANDLERS();
#endif

    // Start the timer tick
    EARLY_PRINT_C("Software initialisation \x1b[1;32mcomplete\x1b[0m; Starting system tick...\r\n");
    START_HEART();
    ENABLE_RECV();

    EARLY_PRINT_C("Initialisation complete; Waiting for software upload...\r\n");

    while (!receive_kernel()) {
        EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Receive failed; Ready for retry...\r\n");
    }

    // Wait a short while for the user's terminal to come back...
    BUSYWAIT_C(100000);

    EARLY_PRINT_C("Kernel received okay; Starting...\r\n");

    // Call into the kernel
    kmain(sdb);

    EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b: Kernel should not return! Halting\r\n");

    while (true) {
        HALT();
    }
}
