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
 * Interface with stage1 for SD Card over SPI
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_BBSD_H
#define __ROSCO_M68K_BBSD_H

#include <stdbool.h>
#include <stdint.h>

#ifdef SD_MINIMAL
#ifndef SD_BLOCK_READ_ONLY      // Minimal config precludes non-block-sized reads...
#define SD_BLOCK_READ_ONLY
#endif
#endif

typedef enum {
    BBSD_CARD_TYPE_V1,
    BBSD_CARD_TYPE_V2,
    BBSD_CARD_TYPE_SDHC,
    BBSD_CARD_TYPE_UNKNOWN,
} BBSDCardType;

typedef enum {
    BBSD_INIT_OK,
    BBSD_INIT_IDLE_FAILED,
    BBSD_INIT_CMD8_FAILED,
    BBSD_INIT_ACMD41_FAILED,
} BBSDInitStatus;

typedef struct {
    bool            initialized;
    BBSDCardType    type;
#ifndef SD_BLOCK_READ_ONLY
    bool            have_current_block;     /* if true, the next two members have meaning */
    uint32_t        current_block_start;
    uint16_t        current_block_offset;
    bool            can_partial_read;
#endif
} BBSDCard;

bool BBSD_support_check();
BBSDInitStatus BBSD_initialize(BBSDCard *sd);
bool BBSD_read_block(BBSDCard *sd, uint32_t block, uint8_t *buffer);

#endif /* __ROSCO_M68K_BBSD_H */
