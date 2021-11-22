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
 * Partition access structs and routines
 * (Only MBR is supported yet, GPT maybe TODO).
 * ------------------------------------------------------------
 */
#ifndef __ROSCO_M68K_PART_H
#define __ROSCO_M68K_PART_H

#include <stdint.h>
#include <stdbool.h>
#include "part_mbr.h"

typedef struct {
    uint8_t     status;
    uint8_t     type;
    uint32_t    lba_start;
    uint32_t    sector_count;
} RuntimePart;

typedef struct {
    uint8_t     drive;
    RuntimePart parts[4];
} PartHandle;

int8_t part_init(PartHandle *handle, uint8_t drive);
uint32_t part_read(PartHandle *handle, uint8_t part_num, uint8_t *buffer, uint32_t start, uint32_t count);
bool part_valid(PartHandle *handle, uint8_t part);

#endif//__ROSCO_M68K_PART_H
