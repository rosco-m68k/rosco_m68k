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
 * SD Card loader for stage 2
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include <bbsd.h>
#include "fat_filelib.h"

extern void mcPrint(const char *str);
extern bool BBSD_support_check();
extern bool load_kernel_bin(void *file);

static BBSDCard sd;

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
            return load_kernel_bin(file);
        } else {
            mcPrint(" (not bootable)\r\n");
        }
    }

    return false;
}
