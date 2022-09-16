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
 * Interface with stage1 for ATA PIO
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_ATA_H
#define __ROSCO_M68K_ATA_H

#define ATA_MASTER                  0x0
#define ATA_SLAVE                   0x1

typedef enum {
    ATA_INIT_OK,
    ATA_INIT_NODEVICE,
    ATA_INIT_GENERAL_FAILURE
} ATAInitStatus;

typedef struct {
    uint8_t     device_num;
    uint8_t     model_str[40];
} ATADevice;

bool ATA_support_check();
ATAInitStatus ATA_init(uint32_t drive, ATADevice *dev);
uint32_t ATA_read_sectors(uint8_t *buf, uint32_t lba, uint32_t num, ATADevice *dev);

#endif // __ROSCO_M68K_ATA_H
