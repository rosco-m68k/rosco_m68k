/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c) 2021 Ross Bamford & Contributors
 * MIT License
 *
 * Partition / Filesystem access routines (deals with MBR)
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>
#include "part.h"
#include "part_mbr.h"
#include "ata.h"
#include "bbsd.h"

static MBR buffer;

#ifdef ROSCO_M68K_ATA
#ifdef ATA_DEBUG
extern void mcPrint(char *str);
extern void print_unsigned(uint32_t num, uint8_t base);
#endif
#endif

#ifdef ROSCO_M68K_ATA
PartInitStatus Part_init_ATA(PartHandle *handle, ATADevice *device) {
#ifdef ATA_DEBUG
    mcPrint("S2: Reading ");
    print_unsigned(1, 10);
    mcPrint(" sector(s) @ ");
    print_unsigned(0, 10);
    mcPrint(" from drive ");
    print_unsigned(device->device_num, 10);
    mcPrint(" into buffer at 0x");
    print_unsigned((uint32_t)&buffer, 16);
    mcPrint(" [device is at 0x");
    print_unsigned((uint32_t)device, 16);
    mcPrint("]\r\n");
#endif

    if (ATA_read_sectors((uint8_t*)&buffer, 0, 1, device) == 1) {
        if (buffer.signature[0] == 0x55 && buffer.signature[1] == 0xAA) {
            handle->device_type = PART_DEVICE_TYPE_ATA;
            handle->ata_device = device;

            for (int i = 0; i < 4; i++) {
                handle->parts[i].status = buffer.parts[i].status;
                handle->parts[i].type = buffer.parts[i].type;
                handle->parts[i].lba_start = __builtin_bswap32(buffer.parts[i].lba_start);
                handle->parts[i].sector_count = __builtin_bswap32(buffer.parts[i].sector_count);
            }

            return PART_INIT_OK;
        } else {
            return PART_INIT_BAD_SIGNATURE;
        }
    } else {
        return PART_INIT_READ_FAILURE;
    }
}
#endif

PartInitStatus Part_init_BBSD(PartHandle *handle, BBSDCard *device) {
    if (BBSD_read_block(device, 0, (uint8_t*)&buffer)) {
        if (buffer.signature[0] == 0x55 && buffer.signature[1] == 0xAA) {
            handle->device_type = PART_DEVICE_TYPE_BBSD;
            handle->bbsd_device = device;

            for (int i = 0; i < 4; i++) {
                handle->parts[i].status = buffer.parts[i].status;
                handle->parts[i].type = buffer.parts[i].type;
                handle->parts[i].lba_start = __builtin_bswap32(buffer.parts[i].lba_start);
                handle->parts[i].sector_count = __builtin_bswap32(buffer.parts[i].sector_count);
            }

            return PART_INIT_OK;
        } else {
            return PART_INIT_BAD_SIGNATURE;
        }
    } else {
        return PART_INIT_READ_FAILURE;
    }
}

#ifdef ROSCO_M68K_ATA
static uint32_t Part_read_ATA(PartHandle *handle, uint8_t part_num, uint8_t *buffer, uint32_t start, uint32_t count) {
    if (part_num > 3 || handle->parts[part_num].type == 0) {
        return 0;
    } else {

#ifdef ATA_DEBUG
        mcPrint("S2: Reading ");
        print_unsigned(count, 10);
        mcPrint(" sector(s) @ ");
        print_unsigned(start, 10);
        mcPrint(" [logical] from partition ");
        print_unsigned(part_num, 10);
        mcPrint(" on drive ");
        print_unsigned(handle->device->device_num, 10);
        mcPrint(" into buffer at 0x");
        print_unsigned((uint32_t)buffer, 16);
        mcPrint(" [part is at 0x");
        print_unsigned((uint32_t)handle, 16);
        mcPrint(" ; device is at 0x");
        print_unsigned((uint32_t)handle->device, 16);
        mcPrint("]\r\n");
#endif

        RuntimePart *part = &handle->parts[part_num];
        if (start >= part->sector_count) {
            // Out of range for partition
#ifdef ATA_DEBUG
            mcPrint("  --> OUT OF RANGE\r\n");
#endif
            return 0;
        } else {
            if (count > part->sector_count - start) {
                count = part->sector_count - start;
            }

#ifdef ATA_DEBUG
            mcPrint("  --> Physical sector is ");
            print_unsigned(part->lba_start + start, 10);
            mcPrint("\r\n");
#endif

            return ATA_read_sectors(buffer, part->lba_start + start, count, handle->ata_device);
        }
    }
}
#endif

static uint32_t Part_read_BBSD(PartHandle *handle, uint8_t part_num, uint8_t *buffer, uint32_t start, uint32_t count) {
    if (part_num > 3 || handle->parts[part_num].type == 0) {
        return 0;
    } else {

        RuntimePart *part = &handle->parts[part_num];
        if (start >= part->sector_count) {
            // Out of range for partition
            return 0;
        } else {
            if (count > part->sector_count - start) {
                count = part->sector_count - start;
            }

            for (uint32_t i = 0; i < count; i++) {
                if (!BBSD_read_block(handle->bbsd_device, part->lba_start + start + i, buffer)) {
                    return i;
                }
                buffer += 512;
            }
            return count;
        }
    }
}

uint32_t Part_read(PartHandle *handle, uint8_t part_num, uint8_t *buffer, uint32_t start, uint32_t count) {
    switch (handle->device_type) {
#ifdef ROSCO_M68K_ATA
    case PART_DEVICE_TYPE_ATA:
        return Part_read_ATA(handle, part_num, buffer, start, count);
#endif
    case PART_DEVICE_TYPE_BBSD:
        return Part_read_BBSD(handle, part_num, buffer, start, count);
    default:
        return 0;
    }
}

bool Part_valid(PartHandle *handle, uint8_t part) {
    // status seems unreliable in modern times (macOS MBRs set it 0), so just see if we have a type
    // TODO this can likely be tightened up quite a bit!
    return handle->parts[part].type > 0;
}
