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
#include "bbsd.h"
#include "part.h"

extern void mcPrint(const char *str);
extern bool load_kernel(PartHandle *part);

bool sd_load_kernel() {
    if (!BBSD_support_check()) {
        mcPrint("Warning: No SD support in ROM - This may indicate your ROMs are not built correctly!\r\n");
        return false;
    }

    BBSDCard sd;
    if (BBSD_initialize(&sd) == BBSD_INIT_OK) {
        switch (sd.type) {
        case BBSD_CARD_TYPE_V1:
            mcPrint("SD v1 card:\r\n");
            break;
        case BBSD_CARD_TYPE_V2:
            mcPrint("SD v2 card:\r\n");
            break;
        case BBSD_CARD_TYPE_SDHC:
            mcPrint("SDHC card:\r\n");
            break;
        default:
            mcPrint("Ignoring unrecognised SD card\r\n");
            return false;
        }

        PartHandle part;
        PartInitStatus pinit = Part_init_BBSD(&part, &sd);

        if (pinit == PART_INIT_OK) {
            return load_kernel(&part);
        } else if (pinit == PART_INIT_BAD_SIGNATURE) {
            mcPrint("  Bad partition signature\r\n");
        } else if (pinit == PART_INIT_READ_FAILURE) {
            mcPrint("  Partition read failure\r\n");
        } else if (pinit == PART_INIT_GENERAL_FAILURE) {
            mcPrint("  Partition init general failure\r\n");
        } else {
            mcPrint("  Partition init - unknown result!\r\n");
        }
    }

    return false;
}
