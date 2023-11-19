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
 * Main low-level implementation for firmware ATA PIO
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>
#include <machine.h>
#include "ata.h"
#include "ata_identify.h"

#define OP_TIMEOUT 500000

extern void FW_PRINT_C(char *);
#ifdef ATA_DEBUG
extern void print_unsigned(uint32_t, uint8_t);
#endif

static volatile uint16_t *idereg = (volatile uint16_t *)IDE_BASE;

static uint8_t ata_m = 0;
static uint8_t ata_m_modelnum[41];
static uint8_t ata_s = 0;
static uint8_t ata_s_modelnum[41];

static uint8_t ata_buf[512];
static uint8_t selected_drive = 0xFF;  /* no drive by default */

//static uint16_t *word_buf = (uint16_t*)ata_buf;

//static bool virq = false;
//static uint16_t vstatus;
//static uint16_t verror;

// TODO not currently used, drive interrupts perma-disabled...
//static
//__attribute__ ((interrupt)) void autovector_ipl_3_handler(void) {
//    // Not doing any actual work in here, as we're just in polled mode for now.
//    // We'll just set some flags we can ignore elsewhere.
//    virq = true;
//    vstatus = idereg[ATA_REG_RD_STATUS] & 0x00FF;
//    verror = idereg[ATA_REG_RD_ERROR] & 0x00FF;
//  if (vread) {
//      if (vstatus & 0x0008)             // DRQ bit
//          for (int i = 0; i < 256; i++)
//              word_buf[i] = idereg[ATA_REG_RD_DATA];
//  }
//}

static void ata_select_drive(uint8_t i) {
    if (i != selected_drive) {
        if (i == ATA_MASTER) {
            idereg[ATA_REG_WR_DEVSEL] = (uint16_t)0xA0;
        } else {
            idereg[ATA_REG_WR_DEVSEL] = (uint16_t)0xB0;
        }

        selected_drive = i;
    }
}

static bool ata_await_ready() {
    uint32_t timeout = 0;

    // TODO some kind of timeout here. Currently hanging if IDE interface has no drives...
    while ((idereg[ATA_REG_RD_ALT_STATUS] & 0x00C0) != 0x0040 && timeout++ < OP_TIMEOUT)
        continue;

    return (timeout < OP_TIMEOUT);
}

static bool ata_await_not_busy() {
    uint32_t timeout = 0;
    
    while ((idereg[ATA_REG_RD_STATUS] & ATA_SR_BSY) != 0 && timeout++ < OP_TIMEOUT)
        continue;

    return (timeout < OP_TIMEOUT);
}

uint8_t ata_identify(uint8_t *buf, uint8_t drive) {
    uint32_t timeout = 0;

    ata_select_drive(drive);

    if (!ata_await_ready()) {
        return 0;
    }

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
        if (!ata_await_not_busy()) {
            // timeout - return no init
            return 0;
        }

        pm_stat_read: status =  idereg[ATA_REG_RD_STATUS] & 0xFF;
        if (status & ATA_SR_ERR) {
            // Error - return no init
            return 0;
        }

        if (timeout++ == OP_TIMEOUT) {
            return 0;
        }

        while (!(status & ATA_SR_DRQ))
            goto pm_stat_read;

        /* Do the read */
        for (int i = 0; i < 256; i++) {
            *(uint16_t*) (buf + i * 2) = idereg[ATA_REG_RD_DATA];
        }

        return 1;
    } else {
        return 0;
    }
}

static void ata_delay_for_a_bit() {
    uint16_t temp;
    for (int i = 0; i < 4; i++)
        temp &= idereg[ATA_REG_RD_ALT_STATUS];
}

static uint8_t ata_poll() {
    uint16_t temp;
    uint32_t timeout = 0;

    for (int i = 0; i < 4; i++)
        temp &= idereg[ATA_REG_RD_ALT_STATUS];

    retry: ;
    if (timeout++ > OP_TIMEOUT) {
        return 0;
    }

    uint8_t status = idereg[ATA_REG_RD_STATUS] & 0xFF;

    if (status & ATA_SR_BSY)
        goto retry;

    timeout = 0;

    retry2: status = idereg[ATA_REG_RD_STATUS] & 0xFF;
    if (status & ATA_SR_ERR) {
        // ERR set - need some way to signal this maybe...
        return 0;
    }

    if (timeout++ > OP_TIMEOUT) {
        return 0;
    }

    if (!(status & ATA_SR_DRQ))
        goto retry2;

    return 1;
}

static uint8_t ata_read_one(uint8_t *buf, uint32_t lba, uint8_t drive) {

#ifdef ATA_DEBUG
    FW_PRINT_C("  S1: ata_read_one @");
    print_unsigned(lba, 10);
    FW_PRINT_C(" into buffer at 0x");
    print_unsigned((uint32_t)buf, 16);
    FW_PRINT_C(": ");
#endif

    if (drive != ATA_MASTER && drive != ATA_SLAVE) {
#ifdef ATA_DEBUG
        FW_PRINT_C("BAD DRIVE #");
        print_unsigned(drive, 10);
        FW_PRINT_C("\r\n");
#endif
        return 0;
    }

    uint8_t cmd = (drive == ATA_MASTER ? 0xE0 : 0xF0);

    if (!ata_await_ready()) {
#ifdef ATA_DEBUG
        FW_PRINT_C("ERROR: ata_await_ready timeout\r\n");
#endif
        return 0;
    }

    idereg[ATA_REG_WR_DEVSEL] = (cmd | (uint8_t) ((lba >> 24 & 0x0F)));
    idereg[ATA_REG_WR_SECTOR_COUNT] = 1;
    idereg[ATA_REG_WR_LBA_7_0] = (uint8_t) (lba);
    idereg[ATA_REG_WR_LBA_15_8] = (uint8_t) ((lba) >> 8);
    idereg[ATA_REG_WR_LBA_23_16] = (uint8_t) ((lba) >> 16);
    idereg[ATA_REG_WR_COMMAND] =  ATA_CMD_READ_PIO;

    if (!ata_poll()) {
#ifdef ATA_DEBUG
        FW_PRINT_C("ERROR: ata_poll timeout\r\n");
#endif
        return 0;
    }

    for (int i = 0; i < 256; i++) {
        *(uint16_t*) (buf + i * 2) = __builtin_bswap16(idereg[ATA_REG_RD_DATA]);
    }

    ata_delay_for_a_bit();

#ifdef ATA_DEBUG
    FW_PRINT_C("OK\r\n");
#endif

    return 1;
}

static uint32_t ata_read(uint8_t *buf, uint32_t lba, uint32_t num, uint8_t drive) {
    ata_select_drive(drive);

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
        return 0;
    }

    if (!ata_await_ready()) {
        return 0;
    }

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

static uint32_t ata_write(uint8_t *buf, uint32_t lba, uint32_t num, uint8_t drive) {
    ata_select_drive(drive);

    for (uint32_t i = 0; i < num; i++) {
        if (!ata_write_one(buf, lba + i, drive)) {
            return i;
        }
        buf += 512;
    }
    return num;
}

static inline void copy_ident(uint8_t *dest, uint8_t *src) {
    for (int i = 0; i < 40; i++) { // N.B. off-by-one is deliberate for null-termination!
        dest[i] = src[i];
    }
}

static void ata_probe() {
    ATA_IDENTIFY_DEVICE_DATA *ident = (ATA_IDENTIFY_DEVICE_DATA*)ata_buf;

    if (ata_identify(ata_buf, ATA_MASTER)) {
        ata_m = 1;
        copy_ident(ata_m_modelnum, ident->ModelNumber);
    }

    if (ata_identify(ata_buf, ATA_SLAVE)) {
        ata_s = 1;
        copy_ident(ata_s_modelnum, ident->ModelNumber);
    }
}

// N.B. Using the bootstrap's BERR handler here while we probe the IDE device.
// This means ata_init **must** be called before any video devices are
// initialized!

static uint8_t *berr_flag = (uint8_t*)BERR_FLAG;

void TRY_DISABLE_ATA_INTERRUPT(volatile uint16_t *idereg);

void ata_init() {
    TRY_DISABLE_ATA_INTERRUPT(idereg);

    FW_PRINT_C("Initializing hard drives... ");

    if (!*berr_flag) {

        //
        //    void (**vector)(void);
        //
        //    printf("Setting Autovector IPL handlers\n\r");
        //    vector = (void (**)(void))(&_INITIAL_STACK);
        //    vector[27] = autovector_ipl_3_handler;

        // Enumerate drives for later use
        ata_probe();

        FW_PRINT_C("Done\r\n");

        if (ata_m) {
            FW_PRINT_C("IDE Master  : ");
            FW_PRINT_C((char*)ata_m_modelnum);
            FW_PRINT_C("\r\n");
        } else {
            FW_PRINT_C("IDE Master  : <Not found>\r\n");
        }
        if (ata_s) {
            FW_PRINT_C("IDE Slave   : ");
            FW_PRINT_C((char*)ata_s_modelnum);
            FW_PRINT_C("\r\n");
        } else {
            FW_PRINT_C("IDE Slave   : <Not found>\r\n");
        }
    } else {
        FW_PRINT_C("No IDE interface found\r\n");
    }
}


/*********** Routines called from EFP functions */
uint32_t ATA_init(uint32_t drive, ATADevice *dev) {
    if (drive == ATA_MASTER) {
        if (ata_m) {
            dev->device_num = ATA_MASTER;
            copy_ident(dev->model_str, ata_m_modelnum);
            return ATA_INIT_OK;
        } else {
            return ATA_INIT_NODEVICE;
        }
    } else if (drive == ATA_SLAVE) {
        if (ata_s) {
            dev->device_num = ATA_SLAVE;
            copy_ident(dev->model_str, ata_s_modelnum);
            return ATA_INIT_OK;
        } else {
            return ATA_INIT_NODEVICE;
        }
    } else {
        return ATA_INIT_GENERAL_FAILURE;
    }
}

uint32_t ATA_read_sectors(uint8_t *buf, uint32_t lba, uint32_t num, ATADevice *dev) {
#ifdef ATA_DEBUG
    FW_PRINT_C("S1: Reading ");
    print_unsigned(num, 10);
    FW_PRINT_C(" sector(s) @ ");
    print_unsigned(lba, 10);
    FW_PRINT_C(" from drive ");
    print_unsigned(dev->device_num, 10);
    FW_PRINT_C(" into buffer at 0x");
    print_unsigned((uint32_t)buf, 16);
    FW_PRINT_C(" [device is at 0x");
    print_unsigned((uint32_t)dev, 16);
    FW_PRINT_C("]\r\n");
#endif

    return ata_read(buf, lba, num, dev->device_num);
}

uint32_t ATA_write_sectors(uint8_t *buf, uint32_t lba, uint32_t num, ATADevice *dev) {
    return ata_write(buf, lba, num, dev->device_num);
}

uint32_t ATA_ident(uint8_t *buf, ATADevice *dev) {
    return ata_identify(buf, dev->device_num);

}
