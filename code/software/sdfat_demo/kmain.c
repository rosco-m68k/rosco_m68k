/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v1
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Demo usage of the sdfat standard library
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <sdfat.h>

void kmain() {
    if (SD_check_support()) {
        printf("SD support is available in ROM, initializing FAT lib...\n");

        if (SD_FAT_initialize()) {
            printf("Init looks good, printing directory listing for /...\n");

            fl_listdirectory("/");
        } else {
            printf("Failed to init\n");
        }
    } else {
        printf("This demo requires SD support in ROM, but it isn't available :(\n");
    }
}

