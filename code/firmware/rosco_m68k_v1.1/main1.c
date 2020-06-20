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

extern uint32_t decompress_stage2(uint32_t src_addr, uint32_t size);
extern void print_unsigned(unsigned int num, unsigned char base);

/*
 * This is what a Stage 2 entry point should look like.
 */
typedef void (*Stage2)();

// Linker defines
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end, _end;
extern uint32_t _zip_start, _zip_end;

static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock * const)0x400;

// Stage 2 loads at 0x2000
uint8_t *stage2_load_ptr = (uint8_t*) 0x2000;
static Stage2 stage2 = (Stage2) 0x2000;

// Probably not needed any more...
void linit() {
  // copy .data
  for (uint32_t *dst = &_data_start, *src = &_code_end; dst < &_data_end; *dst = *src, dst++, src++);

  // zero .bss
  for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);
}

uint32_t get_zip_size() {
  return (uint32_t)&_zip_end - (uint32_t)&_zip_start;
}

/* Main stage 1 entry point */
noreturn void main1() {
    if (sdb->magic != 0xB105D47A) {
        EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: SDB Magic mismatch; SDB is trashed. Halting.\r\n");
        HALT();
    }

    // Start the timer tick
    EARLY_PRINT_C("Stage 1  initialisation \x1b[1;32mcomplete\x1b[0m; Starting system tick...\r\n");
    START_HEART();

    if (!decompress_stage2((uint32_t)&_zip_start, get_zip_size())) {
        EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Stage 2 decompression failed; Halting.\r\n");
        
        while (true) {
            HALT();
        }
    }

    // Call into stage 2
    stage2();

    EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b: Stage 2 should not return! Halting\r\n");

    while (true) {
        HALT();
    }
}

// TODO these are duplicated in stage2, find a way not to do that...
// (Can't do the same way as for the EASY_ stuff as they're GCC 
// intrinsics so have to be available at link time. Could stub them 
// and call back the same way, but probably not worth the few bytes...)
unsigned long divmod(unsigned long num, unsigned long den, int mod) {
    unsigned long bit = 1;
    unsigned long res = 0;

    while (den < num && bit && !(den & (1L << 31))) {
        den <<= 1;
        bit <<= 1;
    }

    while (bit) {
        if (num >= den) {
            num -= den;
            res |= bit;
        }

        bit >>= 1;
        den >>= 1;
    }

    if (mod) {
        return num;
    } else {
        return res;
    }
}

uint32_t __divsi3(uint32_t dividend, uint32_t divisor) {
    return divmod(dividend, divisor, 0);
}
uint32_t __modsi3(uint32_t dividend, uint32_t divisor) {
    return divmod(dividend, divisor, 1);
}
uint32_t __udivsi3(uint32_t dividend, uint32_t divisor) {
    return divmod(dividend, divisor, 0);
}
uint32_t __umodsi3(uint32_t dividend, uint32_t divisor) {
    return divmod(dividend, divisor, 1);
}

