/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2019-2024 Ross Bamford and contributors
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

#include "kmachine.h"
#include "pmm.h"
#include "slab.h"
#include "list.h"
#include "task.h"
#include "kernelapi.h"


// only one Xosera console at a time
#if defined(XOSERA_API_MINIMAL)
#include "xosera_ansiterm_m68k.h"
#include "intro.h"
#endif
#ifdef VIDEO9958_CON
#include "video9958.h"
#endif
#ifdef HAVE_DEBUG_STUB
extern void debug_stub();
#endif

#define INIT_STACK_VEC_ADDRESS      0x0
#define RESET_VEC_ADDRESS           0x4
#define MEM_SIZE_SDB_ADDRESS        0x414
#define PROGRAM_LOADER_EFP_ADDRESS  0x448
#define PROGRAM_EXIT_EFP_ADDRESS    0x490

extern void INSTALL_EASY68K_TRAP_HANDLERS();
#ifdef BLOCKDEV_SUPPORT
extern void ata_init();
extern void INSTALL_BLOCKDEV_HANDLERS();
#endif
extern noreturn void warm_boot(void);
extern noreturn void hot_boot(void);
extern uint32_t decompress_stage2(uint32_t src_addr, uint32_t size);
extern uint32_t cpuspeed(uint8_t model);
extern void print_unsigned(uint32_t num, uint8_t base);
extern void initialize_keyboard();
#ifdef LATE_BANNER
extern void PRINT_BANNER(void);
#endif

/*
 * This is what a Stage 2 entry point should look like.
 */
typedef void (*Stage2)(void);

// Linker defines
extern uint16_t _data_start, _data_end;
extern uint16_t _data_load_start, _data_load_end;
extern uint16_t _bss_start, _bss_end;
extern uint16_t _code_start, _code_end;
extern unsigned char _zip_start, _zip_end;

static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock *)0x400;
static uint32_t * const init_stack_vector_ptr = (uint32_t *)INIT_STACK_VEC_ADDRESS;
static uint32_t * const reset_vector_ptr = (uint32_t *)RESET_VEC_ADDRESS;
static uint32_t * const mem_size_sdb_ptr = (uint32_t *)MEM_SIZE_SDB_ADDRESS;
static uint32_t * const program_loader_ptr = (uint32_t *)PROGRAM_LOADER_EFP_ADDRESS;
static uint32_t * const prog_exit_ptr = (uint32_t *)PROGRAM_EXIT_EFP_ADDRESS;

// Stage 2 loads at 0xF0000
extern void STAGE2_LOAD(void);
static Stage2 stage2 = &STAGE2_LOAD;

noreturn void main1();

noreturn void linit() {
  // copy .data
  for (uint16_t *dst = &_data_start, *src = &_data_load_start; dst < &_data_end; *dst = *src, dst++, src++);

  // zero .bss
  for (uint16_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);

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
        FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Stage 2 failed; Stop.\r\n");
        
        while (true) {
            BUSYWAIT_C(10000);
            //HALT();
        }
    }

    // Call into stage 2
    stage2();

    FW_PRINT_C("\x1b[1;31mSEVERE\x1b: Stage 2 should not return! Stop.\r\n");

    HALT();
}

static void initialize_loader_efp() {
    *program_loader_ptr = (uint32_t)default_program_loader;
}

#ifdef WITH_KERNEL
static void initialize_kernel(void) {
    api_init();
    pmm_init();
    slab_init();    
    irq_init();
    task_init();
}
#else
#define initialize_kernel(...)
#endif

noreturn void pre_warm_boot() {
    initialize_kernel();
    warm_boot();
}

static void initialize_warm_reboot() {
    *init_stack_vector_ptr = *mem_size_sdb_ptr;
    *prog_exit_ptr = *reset_vector_ptr = (uint32_t)pre_warm_boot;
}

void print_cpu_mem_info() {
    FW_PRINT_C("MC680");
    if (sdb->cpu_model == 0) { 
      FW_PRINT_C("0");
    } else if (sdb->cpu_model == 1) {
      FW_PRINT_C("1");
    } else if (sdb->cpu_model == 2) {
      FW_PRINT_C("2");
    } else if (sdb->cpu_model == 3) {
      FW_PRINT_C("3");
    } else if (sdb->cpu_model == 4) {
      FW_PRINT_C("4");
    } else if (sdb->cpu_model == 6) {
      FW_PRINT_C("6");
    } else {
      FW_PRINT_C("?");
    }

    uint32_t speed = sdb->cpu_speed / 1000;

    FW_PRINT_C("0 CPU @ ");
    print_unsigned(speed / 10, 10);
    FW_PRINT_C(".");
    print_unsigned(speed % 10, 10);
    FW_PRINT_C("MHz with ");
    print_unsigned(sdb->memsize, 10);
    FW_PRINT_C(" bytes RAM\r\n"); 
}

/* Main stage 1 entry point - Only called during cold boot */
noreturn void main1() {
#ifdef LATE_BANNER    
    bool have_video = false;
#endif

    if (sdb->magic != 0xB105D47A) {
        FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: SDB Magic mismatch; SDB is trashed. Stop.\r\n");
        HALT();
    }

    // Start the timer tick
#ifndef NO_TICK
    START_HEART();
#endif

    // Initialize the keyboard if available
    initialize_keyboard();

    INSTALL_EASY68K_TRAP_HANDLERS();

#if defined(XOSERA_API_MINIMAL)
    if (XANSI_HAVE_XOSERA()) {
#ifdef LATE_BANNER
        have_video = true;
#endif
        intro();
        goto skip9958;
    }
#endif

#ifdef VIDEO9958_CON
    if (HAVE_V9958()) {
#ifdef LATE_BANNER        
        have_video = true;
#endif
        V9958_CON_INIT();
        V9958_CON_INSTALLHANDLERS();
    }
#endif

#if defined(XOSERA_API_MINIMAL)
skip9958:
#endif

#ifdef LATE_BANNER
if (!have_video) {
    PRINT_BANNER();
}
#endif

    // Now we have tick, we can determine CPU speed
#ifdef NO_TICK
    sdb->cpu_speed = 0;
#else
    sdb->cpu_speed = cpuspeed(sdb->cpu_model);
#endif

    print_cpu_mem_info();

#ifdef BLOCKDEV_SUPPORT
#ifdef ROSCO_M68K_ATA
    ata_init();
#endif
    INSTALL_BLOCKDEV_HANDLERS();
#endif

#ifdef HAVE_DEBUG_STUB
    debug_stub();
#endif

    // Initialize the EFP's PROGRAM_LOADER func with the default loader to begin with
    initialize_loader_efp();

    // We have enough setup done now that we can handle future warm reboot. Let's set that up..
    initialize_warm_reboot();

    // Initialize the kernel
    initialize_kernel();

    // Reload stack pointer and call program loader
    hot_boot();
}
