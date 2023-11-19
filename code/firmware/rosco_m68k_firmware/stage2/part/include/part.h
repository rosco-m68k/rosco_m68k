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
 * Partition access structs and routines (readonly, for firmware)
 * (Only MBR is supported yet, GPT maybe TODO).
 * ------------------------------------------------------------
 */
#ifndef __ROSCO_M68K_PART_H
#define __ROSCO_M68K_PART_H

#include <stdint.h>
#include <stdbool.h>

#ifdef ROSCO_M68K_ATA
#include "ata.h"
#endif

#include "bbsd.h"
#include "part_mbr.h"

typedef enum {
    PART_INIT_OK,
    PART_INIT_READ_FAILURE,
    PART_INIT_BAD_SIGNATURE,
    PART_INIT_GENERAL_FAILURE
} PartInitStatus;

typedef struct {
    uint8_t     status;
    uint8_t     type;
    uint32_t    lba_start;
    uint32_t    sector_count;
} RuntimePart;

typedef enum {
#ifdef ROSCO_M68K_ATA
    PART_DEVICE_TYPE_ATA,
#endif
    PART_DEVICE_TYPE_BBSD,
} PartDeviceType;

typedef struct {
    PartDeviceType device_type;
    union {
#ifdef ROSCO_M68K_ATA
        ATADevice   *ata_device;
#endif
        BBSDCard    *bbsd_device;
    };
    RuntimePart parts[4];
} PartHandle;

#ifdef ROSCO_M68K_ATA
PartInitStatus Part_init_ATA(PartHandle *handle, ATADevice *device);
#endif
PartInitStatus Part_init_BBSD(PartHandle *handle, BBSDCard *device);
uint32_t Part_read(PartHandle *handle, uint8_t part_num, uint8_t *buffer, uint32_t start, uint32_t count);
bool Part_valid(PartHandle *handle, uint8_t part);

#endif//__ROSCO_M68K_PART_H
