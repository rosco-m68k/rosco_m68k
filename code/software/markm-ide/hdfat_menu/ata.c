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
 * Main low-level implementation for ATA PIO driver
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <machine.h>
#include "ata.h"
#include "ata_identify.h"

static volatile uint16_t *idereg = (volatile uint16_t *)IDE_BASE;

static uint8_t ata_m = 0;
static uint8_t ata_s = 0;

uint8_t ata_buf[512];
uint16_t *word_buf = (uint16_t*)ata_buf;

static bool virq = false;
static uint16_t vstatus;
static uint16_t verror;


// TODO not currently used, drive interrupts perma-disabled...
static
__attribute__ ((interrupt)) void autovector_ipl_3_handler(void) {
    // Not doing any actual work in here, as we're just in polled mode for now.
    // We'll just set some flags we can ignore elsewhere.
    virq = true;
    vstatus = idereg[ATA_REG_RD_STATUS] & 0x00FF;
    verror = idereg[ATA_REG_RD_ERROR] & 0x00FF;
//  if (vread) {
//      if (vstatus & 0x0008)             // DRQ bit
//          for (int i = 0; i < 256; i++)
//              word_buf[i] = idereg[ATA_REG_RD_DATA];
//  }
}

void ata_select_drive(uint8_t i) {
    if (i == ATA_MASTER)
        idereg[ATA_REG_WR_DEVSEL] = (uint16_t)0xA0;
    else
        idereg[ATA_REG_WR_DEVSEL] = (uint16_t)0xB0;
}

static void ata_await_ready() {
    while ((idereg[ATA_REG_RD_ALT_STATUS] & 0x00C0) != 0x0040)
      continue;
}


uint8_t ata_identify(uint8_t drive) {
    uint16_t io = 0;
    ata_select_drive(drive);

    ata_await_ready();

    /* ATA specs say these values must be zero before sending IDENTIFY */
    idereg[ATA_REG_WR_SECTOR_COUNT] = 0;
    idereg[ATA_REG_WR_LBA_7_0] = 0;
    idereg[ATA_REG_WR_LBA_15_8] = 0;
    idereg[ATA_REG_WR_LBA_23_16] = 0;

    /* Send IDENTIFY */
    idereg[ATA_REG_WR_COMMAND] = ATA_CMD_IDENTIFY;

    /* Read status */
    uint16_t status = idereg[ATA_REG_RD_STATUS] & 0xFF;
    if (status) {
        /* Poll until BSY is clear. */
        while ((idereg[ATA_REG_RD_STATUS] & ATA_SR_BSY) != 0)
            ;
        pm_stat_read: status =  idereg[ATA_REG_RD_STATUS] & 0xFF;
        if (status & ATA_SR_ERR) {
            printf("WARN: %s has ERR set. Will disable this device.\n", drive == ATA_MASTER ? "Master" : "Slave");
            return 0;
        }
        while (!(status & ATA_SR_DRQ))
            goto pm_stat_read;

        /* Do the read */
        for (int i = 0; i < 256; i++) {
            *(uint16_t*) (ata_buf + i * 2) = idereg[ATA_REG_RD_DATA];
        }

        return 1;
    } else {
        return 0;
    }
}

static void ata_delay_for_a_bit() {
    uint16_t temp;
    for (int i = 0; i < 4; i++)
        temp = idereg[ATA_REG_RD_ALT_STATUS];
}

static uint8_t ata_poll() {
    uint16_t temp;

    for (int i = 0; i < 4; i++)
        temp = idereg[ATA_REG_RD_ALT_STATUS];

    retry: ;
    uint8_t status = idereg[ATA_REG_RD_STATUS] & 0xFF;

    if (status & ATA_SR_BSY)
        goto retry;

    retry2: status = idereg[ATA_REG_RD_STATUS] & 0xFF;
    if (status & ATA_SR_ERR) {
        printf("SEVERE: ERR set, device failure!\n");
        return 0;
    }

    if (!(status & ATA_SR_DRQ))
        goto retry2;

    return 1;
}

static uint8_t ata_read_one(uint8_t *buf, uint32_t lba, uint8_t drive) {
    if (drive != ATA_MASTER && drive != ATA_SLAVE) {
        printf("SEVERE: unknown drive!\n");
        return 0;
    }

    uint8_t cmd = (drive == ATA_MASTER ? 0xE0 : 0xF0);

    ata_await_ready();

    idereg[ATA_REG_WR_DEVSEL] = (cmd | (uint8_t) ((lba >> 24 & 0x0F)));
    idereg[ATA_REG_WR_SECTOR_COUNT] = 1;
    idereg[ATA_REG_WR_LBA_7_0] = (uint8_t) (lba);
    idereg[ATA_REG_WR_LBA_15_8] = (uint8_t) ((lba) >> 8);
    idereg[ATA_REG_WR_LBA_23_16] = (uint8_t) ((lba) >> 16);
    idereg[ATA_REG_WR_COMMAND] =  ATA_CMD_READ_PIO;

    if (!ata_poll()) {
        return 0;
    }

    for (int i = 0; i < 256; i++) {
        *(uint16_t*) (buf + i * 2) = __builtin_bswap16(idereg[ATA_REG_RD_DATA]);
    }

    ata_delay_for_a_bit();
    return 1;
}

uint32_t ata_read(uint8_t *buf, uint32_t lba, uint32_t num, uint8_t drive) {
    for (uint32_t i = 0; i < num; i++) {
        if (!ata_read_one(buf, lba + i, drive)) {
            return i;
        }
        buf += 512;
    }
    return num;
}

static uint8_t ata_write_one(uint8_t *buf, uint32_t lba, uint8_t drive) {
    uint16_t *wbuf = (uint16_t*)buf;

    if (drive != ATA_MASTER && drive != ATA_SLAVE) {
        printf("SEVERE: unknown drive!\n");
        return 0;
    }

    ata_await_ready();

    uint8_t cmd = (drive == ATA_MASTER ? 0xE0 : 0xF0);

    idereg[ATA_REG_WR_DEVSEL] = (cmd | (uint8_t) ((lba >> 24 & 0x0F)));
    idereg[ATA_REG_WR_SECTOR_COUNT] = 1;
    idereg[ATA_REG_WR_LBA_7_0] = (uint8_t) (lba);
    idereg[ATA_REG_WR_LBA_15_8] = (uint8_t) ((lba) >> 8);
    idereg[ATA_REG_WR_LBA_23_16] = (uint8_t) ((lba) >> 16);
    idereg[ATA_REG_WR_COMMAND] = ATA_CMD_WRITE_PIO;

    if (!ata_poll()) {
        return 0;
    }

    for (int i = 0; i < 256; i++) {
        idereg[ATA_REG_WR_DATA] = __builtin_bswap16(wbuf[i]);
    }

    ata_delay_for_a_bit();
    return 1;
}

uint32_t ata_write(uint8_t *buf, uint32_t lba, uint32_t num, uint8_t drive) {
    for (uint32_t i = 0; i < num; i++) {
        if (!ata_write_one(buf, lba + i, drive)) {
            return i;
        }
        buf += 512;
    }
    return num;
}

void ata_probe() {
    char str[40];

    ATA_IDENTIFY_DEVICE_DATA *ident = (ATA_IDENTIFY_DEVICE_DATA*)ata_buf;

    if (ata_identify(ATA_MASTER)) {
        ata_m = 1;
        printf("M: %s\n", ident->ModelNumber);
    } else {
        printf("M: <Offline>\n");
    }
    if (ata_identify(ATA_SLAVE)) {
        ata_s = 1;
        printf("S: %s\n", ident->ModelNumber);
    } else {
        printf("S: <Offline>\n");
    }
}

void ata_init() {
    printf("Disabling interrupt\r\n");
    idereg[ATA_REG_WR_DEVICE_CONTROL] = 0x0002;
//
//    void (**vector)(void);
//
//    printf("Setting Autovector IPL handlers\n\r");
//    vector = (void (**)(void))(&_INITIAL_STACK);
//    vector[27] = autovector_ipl_3_handler;

    printf("Enumerating drives...\n");
    ata_probe();
}
