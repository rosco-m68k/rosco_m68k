/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2022 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Kernel loader for stage 2
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include "fat_filelib.h"
#include "system.h"

extern void mcPrint(const char *str);

extern uint8_t *kernel_load_ptr;

extern void print_unsigned(uint32_t num, uint8_t base);

static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock * const)0x400;

bool load_kernel_bin(void *file) {
    uint32_t start = sdb->upticks;

    mcPrint("Loading");
    int c;
    uint8_t *current_load_ptr = kernel_load_ptr;
    uint8_t b = 0;
    while ((c = fl_fread(current_load_ptr, 512, 1, file)) > 0) {
        current_load_ptr += c;
        if (++b == 8) {
            mcPrint(".");
            b = 0;
        }
    }
    mcPrint("\r\n");

    fl_fclose(file);

    if (c != EOF) {
        mcPrint("*** Kernel load error\r\n");

        return false;
    } else {
        uint32_t total_ticks = sdb->upticks - start;
        uint32_t total_secs = (total_ticks + 50) / 100;
        uint32_t load_size = current_load_ptr - kernel_load_ptr;
        mcPrint("Loaded ");
        print_unsigned(load_size, 10);
        mcPrint(" bytes in ~");
        print_unsigned(total_secs ? total_secs : 1, 10);
        mcPrint(" sec.\r\n");

        return true;
    }
}
