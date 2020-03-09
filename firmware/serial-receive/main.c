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
#include "rtlsupport.h"

/*
 * This is what a Kernel entry point should look like.
 */
typedef void (*LoadFunc)(SystemDataBlock * const);

// Linker defines
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end;

static SystemDataBlock * const sdb = (SystemDataBlock * const)0x400;
static volatile uint8_t * const mfp_gpdr = (uint8_t * const)MFP_GPDR;

extern void ENABLE_RECV();
extern void ENABLE_XMIT();

// Load the kernel at the end of this loader's data section.
// Once the kernel is running it's free to relocate or reuse the loader's memory.
// Memory from 0x1000 is guaranteed to be reusable once the loader is done.
//
// This does mean where the kernel is loaded will vary depending on which loader
// is used, so use PIC, at least for the bit that relocates your kernel!
//
uint8_t *kernel_load_ptr = (uint8_t*) &_data_end;
static LoadFunc* loadfunc = (LoadFunc*) &_data_end;

int receive_kernel();

void kinit() {
  // copy .data
  for (uint32_t *dst = &_data_start, *src = &_code_end; dst < &_data_end; *dst = *src, dst++, src++);

  // zero .bss
  for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);
}

noreturn void kmain() {
    *mfp_gpdr |= 0x80;

    if (sdb->magic != 0xB105D47A) {
        EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: SDB Magic mismatch; SDB is trashed. Halting.\r\n");
        HALT();
    }

    // Start the timer tick
    EARLY_PRINT_C("Software initialisation \x1b[1;32mcomplete\x1b[0m; Starting system tick...\r\n");
    START_HEART();

    EARLY_PRINT_C("Initialisation complete; Entering echo loop...\r\n");

    ENABLE_XMIT();
    ENABLE_RECV();

    while (!receive_kernel()) {
        EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Receive failed; Ready for retry...\r\n");
    }

    EARLY_PRINT_C("Kernel received okay; Starting...\n");

    // Call into the kernel
    (*loadfunc)(sdb);

    EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b: Kernel should not return! Halting\r\n");

    while (true) {
        HALT();
    }
}
