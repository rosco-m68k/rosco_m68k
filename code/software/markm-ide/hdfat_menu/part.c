/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2021 Ross Bamford & Contributors
 * MIT License
 *
 * Partition / Filesystem access routines (deals with MBR)
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include "part.h"
#include "part_mbr.h"
#include "ata.h"

static MBR buffer;

int8_t part_init(PartHandle *handle, uint8_t drive) {
    if (ata_read((uint8_t*)&buffer, 0, 1, drive) == 1) {
        printf("Read success\n");
        if (buffer.signature[0] == 0x55 && buffer.signature[1] == 0xAA) {
            printf("Signature looks good\n");

            handle->drive = drive;

            for (int i = 0; i < 4; i++) {
                handle->parts[i].status = buffer.parts[i].status;
                handle->parts[i].type = buffer.parts[i].type;
                handle->parts[i].lba_start = __builtin_bswap32(buffer.parts[i].lba_start);
                handle->parts[i].sector_count = __builtin_bswap32(buffer.parts[i].sector_count);

                printf("Part: %d @ 0x%08x (%8d sectors) : Status 0x%02x : Type 0x%02x\n", i, handle->parts[i].lba_start, handle->parts[i].sector_count, handle->parts[i].status, handle->parts[i].type);
            }

            return 1;
        } else {
            printf("Bad signature %02x%02x\n", buffer.signature[0], buffer.signature[1]);
            return -2;
        }
    } else {
        printf("Read failed\n");
        return -1;
    }
}

uint32_t part_read(PartHandle *handle, uint8_t part_num, uint8_t *buffer, uint32_t start, uint32_t count) {
    if (part_num > 3 || handle->parts[part_num].type == 0) {
        printf("Partition %d not valid or not present on disk\n", part_num);
        return 0;
    } else {
        RuntimePart *part = &handle->parts[part_num];
        if (start > part->sector_count || start + count > part->sector_count) {
            printf("Read out of range for partition %d", part_num);
            return 0;
        } else {
            return ata_read(buffer, part->lba_start + start, count, handle->drive);
        }
    }
}

bool part_valid(PartHandle *handle, uint8_t part) {
    // status seems unreliable in modern times (macOS MBRs set it 0), so just see if we have a type
    // TODO this can likely be tightened up quite a bit!
    return handle->parts[part].type > 0;
}
