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
    SD_CARD_TYPE_V1,
    SD_CARD_TYPE_V2,
    SD_CARD_TYPE_SDHC,
    SD_CARD_TYPE_UNKNOWN,
} SDCardType;

typedef enum {
    SD_INIT_OK,
    SD_INIT_IDLE_FAILED,
    SD_INIT_CMD8_FAILED,
    SD_INIT_ACMD41_FAILED,
} SDInitStatus;

typedef struct {
    bool            initialized;
    SDCardType      type;
    uint32_t        reserved[4];
} SDCard;

bool SD_check_support();
SDInitStatus SD_initialize(SDCard *sd);
bool SD_read_block(SDCard *sd, uint32_t block, void *buf);
bool SD_write_block(SDCard *sd, uint32_t block, void *buf);
bool SD_read_register(SDCard *sd, uint8_t regcmd, void *buf);

#endif /* __ROSCO_M68K_BBSD_H */
