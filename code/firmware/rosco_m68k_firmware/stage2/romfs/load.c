/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2021-2022 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * IDE HDD loader for stage 2
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include <rosco_m68k/part.h>
#include "load.h"
#include "machine.h"

// TODO this is hardcoded to 360KB, needs to support 1440 (for 720KB) too...
//
// Should be linker-provided really...
#ifndef ROMFS_BASE
#define ROMFS_BASE      0x00E26000
#endif
#ifndef ROMFS_SECTORS
#define ROMFS_SECTORS   720
#endif

static PartInitStatus Part_init_ROMFS(PartHandle *handle, void *addr, uint32_t sectors) {
    // ROMFS doesn't really have partitions, but to fit in with the loading
    // code here, we just fake one.
    //
    MBR *buffer = (MBR*)addr;

    if (buffer->signature[0] == 0x55 && buffer->signature[1] == 0xAA) {
        handle->device_type = PART_DEVICE_TYPE_ROMFS;
        handle->romfs_device = addr;

        handle->parts[0].status = 0x01;
        handle->parts[0].type = 0x01;
        handle->parts[0].lba_start = 0;
        handle->parts[0].sector_count = sectors;

        handle->parts[1].status = 0;
        handle->parts[1].type = 0;
        handle->parts[1].lba_start = 0;
        handle->parts[1].sector_count = 0;

        handle->parts[2].status = 0;
        handle->parts[2].type = 0;
        handle->parts[2].lba_start = 0;
        handle->parts[2].sector_count = 0;

        handle->parts[3].status = 0;
        handle->parts[3].type = 0;
        handle->parts[3].lba_start = 0;
        handle->parts[3].sector_count = 0;

        return PART_INIT_OK;
    }

    return PART_INIT_BAD_SIGNATURE;
}

static bool try_boot(void *addr) {
    PartHandle part;
    PartInitStatus pinit = Part_init_ROMFS(&part, addr, ROMFS_SECTORS);

    FW_PRINT_C("ROMFS Init:");

    if (pinit == PART_INIT_OK) {
        FW_PRINT_C("  Looks good\r\n");
        return load_kernel(&part);
    } else if (pinit == PART_INIT_BAD_SIGNATURE) {
        FW_PRINT_C("  Bad partition signature\r\n");
    } else if (pinit == PART_INIT_READ_FAILURE) {
        FW_PRINT_C("  Partition read failure\r\n");
    } else if (pinit == PART_INIT_GENERAL_FAILURE) {
        FW_PRINT_C("  Partition init general failure\r\n");
    } else {
        FW_PRINT_C("  Partition init - unknown result!\r\n");
    }

    return false;
}

bool romfs_load_kernel() {
    return try_boot((void*)ROMFS_BASE);
}

