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
#include <rosco_m68k/debug.h>

#include "load.h"
#include "machine.h"
#include "system.h"
#include "serial.h"

#if defined(XOSERA_API_MINIMAL)
#include "xosera_m68k_api.h"
#include "xosera_ansiterm_m68k.h"
#ifdef WITH_SPLASH
#include "intro.h"
#endif
#ifdef WITH_BOOT_MENU
#include "model.h"
#include "rosco_boot_menu.h"
#include "parse_menu.h"
#endif
#ifdef WITH_ROMFS
#include "romfs.h"
#endif

#ifdef WITH_BOOT_MENU
#define MAX_MENU_ITEMS                  10
static MenuItem menu_items[MAX_MENU_ITEMS];
static char* menu_texts[MAX_MENU_ITEMS];
#endif
#endif

#ifdef WITH_SPLASH
#define POST_SPLASH_DELAY_MSEC10        50
#endif

// Stage 1 sets this to indicate we have Xosera, so need to close out the init splash...
extern bool stage1_have_xosera;
extern bool skip_splash;
extern bool skip_to_uart_loader;

// Linker defines
extern uint32_t _bss_start, _bss_end;
static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock * const)0x400;

// Flat binary kernels are loaded at the same address regardless of _how_ they're loaded
uint8_t *kernel_load_ptr = (uint8_t*) KERNEL_LOAD_ADDRESS;
KMain kernel_entry = (KMain) KERNEL_LOAD_ADDRESS;

void red_led_off(void);
void MC_DELAY_MSEC_10(int);

void linit() {
    // zero .bss
    for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);
}

#if defined(WITH_BOOT_MENU)
// If this returns true, it means a program has been loaded at the kernel_load_ptr.
//
// Otherwise, it means an 'exit' or bad menu item was selected.
//
// This also initializes the console as a side-effect, which kinda sucks... 
//
typedef enum _boot_menu_res {
    RES_NONE        = 0,    // use default program loader (or load error)
    RES_LOAD_OK     = 1,    // loaded ok
    RES_UART_LOADER = 2     // UART load detected. skip to UART loader
} boot_menu_res;

static boot_menu_res handle_boot_menu(void) {
    // May as well use the kernel load pointer as a temp place to store the menu, we won't need it until after
    // the menu is done anyhow...
    ROMFS_ERR load_menu_result = romfs_try_load("/menu.txt", (void*)ROMFS_BASE, (void*)kernel_load_ptr, 2048);

    if (load_menu_result > 0) {
        int n_items;

        bool menu_result = parse_menu((char*)kernel_load_ptr, load_menu_result, MAX_MENU_ITEMS, menu_items, &n_items);        

        if (menu_result) {
            for (int i = 0; i < n_items; i++) {
                menu_texts[i] = menu_items[i].text;
            }

            int selection = do_boot_menu(menu_texts, n_items);

            XANSI_CON_INIT(false);

            if (selection < 0) {
                FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Boot menu failed; Falling back to program loader...\r\n");
                return RES_NONE;
            }

            if (selection == MENU_SKIP_TO_LOADER) {
                return RES_UART_LOADER;
            }

            ROMFS_ERR load_prog_result;

            switch (menu_items[selection].type) {
            case MENU_ITEM_EXIT:
                return RES_NONE;
            case MENU_ITEM_ROMFS:
                FW_PRINT_C("Loading '");
                FW_PRINT_C(menu_items[selection].text);
                FW_PRINT_C("' - please wait.\r\n");

                load_prog_result = romfs_try_load(menu_items[selection].data, (void*)ROMFS_BASE, (void*)kernel_load_ptr, -1);
                if (load_prog_result > 0) {
                    return RES_LOAD_OK;
                } else {
                    FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Failed to load '");
                    FW_PRINT_C(menu_items[selection].data);
                    FW_PRINT_C("' from ROMFS; Falling back to program loader... \r\n");
                    return RES_NONE;
                }
            default:
                FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Unexpected menu result [PROBABLE FIRMWARE BUG]\r\n");
                return RES_NONE;
            }
        } else {
            XANSI_CON_INIT(false);
        }
    } else {
        XANSI_CON_INIT(false);
    }

    return RES_NONE;
}
#endif

noreturn void lmain() {
    // Always do this for backwards compatibility    
    ENABLE_RECV();

#if defined(XOSERA_API_MINIMAL)
#ifdef WITH_SPLASH
    if (stage1_have_xosera) {
        intro_end();
        if (!skip_splash)
        {
            MC_DELAY_MSEC_10(POST_SPLASH_DELAY_MSEC10);
        }
#endif
#ifdef WITH_BOOT_MENU
        boot_menu_res menu_res = handle_boot_menu();
        if (menu_res == RES_LOAD_OK) {
            goto have_kernel;
        }
#if defined(KERMIT_LOADER) && !defined(MAME_FIRMWARE)
        if (menu_res == RES_UART_LOADER)
            goto start_uart_loader;
#endif
#endif
#ifdef WITH_SPLASH        
    }
#endif
#endif

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
#endif
#  ifdef ROMFS_LOADER
    if (romfs_load_kernel()) {
        goto have_kernel;
    }
#  endif
#ifndef MAME_FIRMWARE
#  if (defined SDFAT_LOADER) || (defined IDE_LOADER)
    FW_PRINT_C("No bootable media found\r\n");
#  endif
#  ifdef KERMIT_LOADER
#    ifdef WITH_BOOT_MENU
start_uart_loader:
#    endif
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

//#if !defined(MAME_FIRMWARE)
#  if defined SDFAT_LOADER || defined IDE_LOADER || defined ROMFS_LOADER
have_kernel:
#  endif
//#endif
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
