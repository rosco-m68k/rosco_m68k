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

#define BUF_LEN 82
#define BUF_MAX BUF_LEN - 2

static uint8_t buf[BUF_LEN];

extern void mcPrint(char *str);
extern void mcBusywait(uint32_t nops);
extern void mcHalt();
extern void ENABLE_RECV();

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

// Kernels are loaded at $28000 regardless of _how_ they're loaded
uint8_t *kernel_load_ptr = (uint8_t*) 0x28000;
static KMain kmain = (KMain) 0x28000;

// This is provided by the SD/FAT loader
int load_kernel();

// This is provided by Kermit
int receive_kernel();

static uint8_t digit(unsigned char digit) {
  if (digit < 10) {
    return (char)(digit + '0');
  } else {
    return (char)(digit - 10 + 'A');
  }
}

void print_unsigned(uint32_t num, uint8_t base) {
  if (base < 2 || base > 36) {
    return;
  }

unsigned char bp = BUF_MAX;

  if (num == 0) {
    buf[bp--] = '0';
  } else {
    while (num > 0) {
      buf[bp--] = digit(num % base);
      num /= base;
    }
  }

  mcPrint((char*)&buf[bp+1]);
}

void linit() {
    // copy .data
    //for (uint32_t *dst = &_data_start, *src = &_code_end; dst < &_data_end; *dst = *src, dst++, src++);

    // zero .bss
    for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);
}

noreturn void lmain() {
    if (kernel_load_ptr != (uint8_t*)0x28000) {
        mcPrint("BAD LINKAGE (DATA)!!! (load_ptr is 0x");
        print_unsigned((uint32_t)kernel_load_ptr, 16);
        mcPrint(")\r\n");
    } else {
        mcPrint("Linkage seems okay...\r\n");
    }

    // Always do this for backwards compatibility
    ENABLE_RECV();

#ifdef EASY68K_TRAP
    INSTALL_EASY68K_TRAP_HANDLERS();
#endif

    mcPrint("Stage 2  initialisation \x1b[1;32mcomplete\x1b[0m; Attempting to load kernel...\r\n");

    if (load_kernel()) {
        goto have_kernel;
    }

    mcPrint("No SD card, or no kernel found on SD Card, giving up...\r\n");

    while (true) {
      mcHalt();
    }

    while (!receive_kernel()) {
        mcPrint("\x1b[1;31mSEVERE\x1b[0m: Receive failed; Ready for retry...\r\n");
    }

    // Wait a short while for the user's terminal to come back...
    mcBusywait(100000);

    mcPrint("Kernel received okay; Starting...\r\n");

have_kernel:
    // Call into the kernel
    kmain(sdb);

    mcPrint("\x1b[1;31mSEVERE\x1b: Kernel should not return! Halting\r\n");

    while (true) {
        mcHalt();
    }
}
