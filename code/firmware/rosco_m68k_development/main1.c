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

#ifdef VIDEO9958_CON
#include "video9958.h"
#endif

#define INIT_STACK_VEC_ADDRESS 0x0
#define RESET_VEC_ADDRESS 0x4
#define MEM_SIZE_SDB_ADDRESS 0x414
#define PROGRAM_LOADER_EFP_ADDRESS 0x448

extern void INSTALL_EASY68K_TRAP_HANDLERS();
#ifdef SDCARD_SUPPORT
extern void INSTALL_SDCARD_HANDLERS();
#endif
extern void warm_boot(void);
extern uint32_t decompress_stage2(uint32_t src_addr, uint32_t size);

/*
 * This is what a Stage 2 entry point should look like.
 */
typedef void (*Stage2)(void);

// Linker defines
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end;
extern uint32_t _zip_start, _zip_end;

static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock * const)0x400;
static uint32_t* program_loader_ptr = (uint32_t*)PROGRAM_LOADER_EFP_ADDRESS;
static uint32_t* reset_vector_ptr = (uint32_t*)RESET_VEC_ADDRESS;
static uint32_t* init_stack_vector_ptr = (uint32_t*)INIT_STACK_VEC_ADDRESS;
static uint32_t* mem_size_sdb_ptr = (uint32_t*)MEM_SIZE_SDB_ADDRESS;

// Stage 2 loads at 0x2000
uint8_t *stage2_load_ptr = (uint8_t*) 0x2000;
static Stage2 stage2 = (Stage2) 0x2000;

noreturn void main1();

noreturn void linit() {
  // copy .data
  for (uint32_t *dst = &_data_start, *src = &_code_end; dst < &_data_end; *dst = *src, dst++, src++);

  // zero .bss
  for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);

  main1();
}

uint32_t get_zip_size() {
  return (uint32_t)&_zip_end - (uint32_t)&_zip_start;
}

/*
 * This function becomes the default loader implementation pointed to by the EFP.
 * It can be swapped out to use different loaders - see InterfaceReference.md.
 */ 
noreturn void default_program_loader() {
    if (!decompress_stage2((uint32_t)&_zip_start, get_zip_size())) {
        FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Stage 2 decompression failed; Halting.\r\n");
        
        while (true) {
            BUSYWAIT_C(10000);
            //HALT();
        }
    }

    // Call into stage 2
    stage2();

    FW_PRINT_C("\x1b[1;31mSEVERE\x1b: Stage 2 should not return! Halting\r\n");

    while (true) {
        HALT();
    }
}

static void initialize_loader_efp() {
    *program_loader_ptr = (uint32_t)default_program_loader;
}

static void initialize_warm_reboot() {
    *init_stack_vector_ptr = *mem_size_sdb_ptr;
    *reset_vector_ptr = (uint32_t)warm_boot;
}

/* Main stage 1 entry point - Only called during cold boot */
noreturn void main1() {
    if (sdb->magic != 0xB105D47A) {
        FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: SDB Magic mismatch; SDB is trashed. Halting.\r\n");
        HALT();
    }

    // Start the timer tick
    FW_PRINT_C("Stage 1  initialisation \x1b[1;32mcomplete\x1b[0m; Starting system tick...\r\n");
    START_HEART();

    INSTALL_EASY68K_TRAP_HANDLERS();

#ifdef SDCARD_SUPPORT
    INSTALL_SDCARD_HANDLERS();
#endif

#ifdef VIDEO9958_CON
    if (HAVE_V9958()) {
        V9958_CON_INIT();
        V9958_CON_INSTALLHANDLERS();
    }
#endif

    // Initialize the EFP's PROGRAM_LOADER func with the default loader to begin with
    initialize_loader_efp();

    // We have enough setup done now that we can handle future warm reboot. Let's set that up..
    initialize_warm_reboot();

    // And let's do default program loader first time around...
    default_program_loader();
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
