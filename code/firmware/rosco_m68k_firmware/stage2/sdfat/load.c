/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * SD Card loader for stage 2
 * ------------------------------------------------------------
 */

#include <stdnoreturn.h>
#include <stdbool.h>
#include <stdint.h>
#include <bbsd.h>
#include "fat_filelib.h"
#include "system.h"

extern void mcPrint(char *str);
extern bool BBSD_support_check();

extern uint8_t *kernel_load_ptr;
static BBSDCard sd;

extern void print_unsigned(uint32_t num, uint8_t base);

static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock * const)0x400;

static int media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    if (!sd.initialized) {
        return 0;
    }

    for(uint32_t i = 0; i < sector_count; i++) {
        if (!BBSD_read_block(&sd, sector + i, buffer)) {
            return 0;
        }
        buffer += 512;
    }

    return 1;
}

static int media_write(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    return 0;
}

bool sd_load_kernel() {
    if (!BBSD_support_check()) {
        mcPrint("Warning: No SD support in ROM - This may indicate your ROMs are not built correctly!\r\n");
        return false;
    }

    if (BBSD_initialize(&sd) == BBSD_INIT_OK) {
        switch (sd.type) {
        case BBSD_CARD_TYPE_V1:
            mcPrint("SD v1 card; ");
            break;
        case BBSD_CARD_TYPE_V2:
            mcPrint("SD v2 card; ");
            break;
        case BBSD_CARD_TYPE_SDHC:
            mcPrint("SDHC card; ");
            break;
        default:
            mcPrint("Ignoring unrecognised SD card");
            return false;
        }

        fl_attach_media(media_read, media_write);

        void *file = fl_fopen("/ROSCODE1.BIN", "r");

        if (file != NULL) {
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

            fl_fclose(file);

            if (c != EOF) {
                mcPrint("\r\n*** SD load error\r\n\r\n");
            } else {
                uint32_t total_ticks = sdb->upticks - start;
                uint32_t total_secs = (total_ticks + 50) / 100;
                uint32_t load_size = current_load_ptr - kernel_load_ptr;
                mcPrint("\r\nLoaded ");
                print_unsigned(load_size, 10);
                mcPrint(" bytes in ~");
                print_unsigned(total_secs ? total_secs : 1, 10);
                mcPrint(" sec.\r\n");

                return true;
            }
        } else {
            mcPrint(" (not bootable)\r\n");
        }
    }

    return false;
}
