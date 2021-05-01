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
 * Main low-level defines and routines for firmware ATA PIO
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_ATA_H
#define __ROSCO_M68K_ATA_H

#define ATA_PRIMARY_DCR_AS          0x3F6
#define ATA_SECONDARY_DCR_AS        0x376

#define ATA_MASTER                  0x0
#define ATA_SLAVE                   0x1

#define IO_BASE                     0x00F80000
#define IDE_BASE                    (IO_BASE + 0x0040)

#define ATA_REG_RD_DATA             0
#define ATA_REG_RD_ERROR            1
#define ATA_REG_RD_SECTOR_COUNT     2
#define ATA_REG_RD_LBA_7_0          3
#define ATA_REG_RD_LBA_15_8         4
#define ATA_REG_RD_LBA_23_16        5
#define ATA_REG_RD_LBA_27_24        6
#define ATA_REG_RD_DEVSEL           6
#define ATA_REG_RD_STATUS           7
#define ATA_REG_RD_ALT_STATUS       14

#define ATA_REG_WR_DATA             0
#define ATA_REG_WR_FEATURES         1
#define ATA_REG_WR_SECTOR_COUNT     2
#define ATA_REG_WR_LBA_7_0          3
#define ATA_REG_WR_LBA_15_8         4
#define ATA_REG_WR_LBA_23_16        5
#define ATA_REG_WR_LBA_27_24        6
#define ATA_REG_WR_DEVSEL           6
#define ATA_REG_WR_COMMAND          7
#define ATA_REG_WR_DEVICE_CONTROL   14

#define ATA_SR_BSY                  0x80
#define ATA_SR_DRDY                 0x40
#define ATA_SR_DF                   0x20
#define ATA_SR_DSC                  0x10
#define ATA_SR_DRQ                  0x08
#define ATA_SR_CORR                 0x04
#define ATA_SR_IDX                  0x02
#define ATA_SR_ERR                  0x01

#define ATA_ER_BBK                  0x80
#define ATA_ER_UNC                  0x40
#define ATA_ER_MC                   0x20
#define ATA_ER_IDNF                 0x10
#define ATA_ER_MCR                  0x08
#define ATA_ER_ABRT                 0x04
#define ATA_ER_TK0NF                0x02
#define ATA_ER_AMNF                 0x01

#define ATA_CMD_READ_PIO            0x20
#define ATA_CMD_READ_PIO_EXT        0x24
#define ATA_CMD_READ_DMA            0xC8
#define ATA_CMD_READ_DMA_EXT        0x25
#define ATA_CMD_WRITE_PIO           0x30
#define ATA_CMD_WRITE_PIO_EXT       0x34
#define ATA_CMD_WRITE_DMA           0xCA
#define ATA_CMD_WRITE_DMA_EXT       0x35
#define ATA_CMD_CACHE_FLUSH         0xE7
#define ATA_CMD_CACHE_FLUSH_EXT     0xEA
#define ATA_CMD_PACKET              0xA0
#define ATA_CMD_IDENTIFY_PACKET     0xA1
#define ATA_CMD_IDENTIFY            0xEC

#define ATA_IDENT_DEVICETYPE        0
#define ATA_IDENT_CYLINDERS         2
#define ATA_IDENT_HEADS             6
#define ATA_IDENT_SECTORS           12
#define ATA_IDENT_SERIAL            20
#define ATA_IDENT_MODEL             54
#define ATA_IDENT_CAPABILITIES      98
#define ATA_IDENT_FIELDVALID        106
#define ATA_IDENT_MAX_LBA           120
#define ATA_IDENT_COMMANDSETS       164
#define ATA_IDENT_MAX_LBA_EXT       200


typedef enum {
    ATA_INIT_OK,
    ATA_INIT_NODEVICE,
    ATA_INIT_GENERAL_FAILURE
} ATAInitStatus;

typedef struct {
    uint8_t     device_num;
    uint8_t     model_str[40];
} ATADevice;

void ata_init();
uint8_t ata_identify(uint8_t *buf, uint8_t drive);
uint32_t ata_read(uint8_t *buf, uint32_t lba, uint32_t num, uint8_t drive);
uint32_t ata_write(uint8_t *buf, uint32_t lba, uint32_t num, uint8_t drive);

#endif // __ROSCO_M68K_ATA_H
