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
 * rosco_m68k Bit-Banged SD Card over SPI
 * ------------------------------------------------------------
 */

#ifndef ROSCO_M68K_DEVICE_BLOCK_H
#define ROSCO_M68K_DEVICE_BLOCK_H

#include <stdbool.h>
#include <stdint.h>

struct _BlockDevice;

typedef uint32_t (*GetBlockSizeFunc)(struct _BlockDevice *device);
typedef bool (*ReadBlockFunc)(struct _BlockDevice *device, uint32_t block, void *buffer);
typedef bool (*ReadFunc)(struct _BlockDevice *device, uint32_t block, uint32_t start_ofs, uint32_t len, void *buffer);
typedef bool (*WriteFunc)(struct _BlockDevice *device, uint32_t block, uint32_t start_ofs, uint32_t len, void *buffer);

typedef struct _BlockDevice {
    bool                initialized;
    GetBlockSizeFunc    getBlockSize;
    ReadBlockFunc       readBlock;
    ReadFunc            read;
    WriteFunc           write;
    void*               device_data;
} BlockDevice;

#endif /* ROSCO_M68K_DEVICE_BLOCK_H */
