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
#include "part.h"
#include "system.h"

extern void mcPrint(const char *str);
extern void print_unsigned(uint32_t num, uint8_t base);

extern uint8_t *kernel_load_ptr;
static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock * const)0x400;

static const char FILENAME_BIN[] = "/ROSCODE1.BIN";

static PartHandle *load_part;
static uint8_t load_part_num;

static int media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    return Part_read(load_part, load_part_num, buffer, sector, sector_count) == sector_count ? 1 : 0;
}

static int media_write(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    return 0;
}

bool load_kernel_bin(void *file) {
    uint32_t start = sdb->upticks;

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

bool load_kernel(PartHandle *part) {
    load_part = part;

    for (int i = 0; i < 4; i++) {
        if (Part_valid(part, i)) {
            load_part_num = i;
            mcPrint("  Partition ");
            print_unsigned(load_part_num + 1, 10);  // Print partition numbers as 1-indexed
            mcPrint(": ");

            fl_attach_media(media_read, media_write);

            void *file;
            if (file = fl_fopen(FILENAME_BIN, "r")) {
                mcPrint("Loading \"");
                mcPrint(FILENAME_BIN);
                mcPrint("\"");
                bool result = load_kernel_bin(file);
                fl_fclose(file);
                return result;
            } else {
                mcPrint("(not bootable)\r\n");
            }
        }
    }

    return false;
}
