/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|         tech demo
 * ------------------------------------------------------------
 * Copyright (c)2021 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * SST39SF0x0 Flash EEPROM interface library
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_SST_H__
#define __ROSCO_M68K_SST_H__

#include <stdint.h>
#include <stdbool.h>

// Manufacturer constants
#define SST_MFR_SST         0xBF

// Device constants
#define SST_DEV_010A        0xB5
#define SST_DEV_020A        0xB6
#define SST_DEV_040         0xB7

#define SST_SECT_SIZE       0x1000

/**
 * Valid commands for SST flash devices.
 */
typedef enum {
  SST_CMD_BYTEPROG  = 0xA0,
  SST_CMD_ERASE     = 0x80,
  SST_CMD_IDENTER   = 0x90,
  SST_CMD_IDEXIT    = 0xF0,
} SST_COMMAND;

/**
 * Device ID for SST flash devices.
 */
typedef struct {
    uint8_t     manufacturer;
    uint8_t     device;
} SSTDeviceId;

/**
 * Fetch device information from the flash ROM at `rom_base`,
 * populating it into the given `sst` struct.
 *
 * Normal reads will be unavailable during this call, so if the
 * flash you're getting info for is the system ROM, you should
 * disable interrupts!
 */
void sst_get_device_info(uint32_t rom_base, SSTDeviceId* sst);

/**
 * Extract the manufacturer ID as a string.
 */
const char* sst_get_manufacturer_name(SSTDeviceId *sst);

/**
 * Extract the device ID as a string.
 */
const char* sst_get_device_name(SSTDeviceId *sst);

/**
 * Erase the given `sector` on the flash at `rom_base`.
 *
 * Normal reads will be unavailable during this call, and the
 * specified sector will be erased afterward (assuming success).
 *
 * If the flash you're erasing is the system ROM you should disable
 * interrupts.
 *
 * If the erased sector is one occupied by system ROM code you
 * should avoid any calls that rely on the system TRAPs
 * until you have a valid ROM again!
 */
bool sst_sector_erase(uint32_t rom_base, uint8_t sector);

/**
 * Erase the flash at `rom_base`.
 *
 * Normal reads will be unavailable during this call, and the
 * device will be erased afterward (assuming success).
 *
 * If the flash you're erasing is the system ROM, you should disable
 * interrupts and avoid any calls that rely on the system TRAPs
 * until you have a valid ROM again!
 */
bool sst_chip_erase(uint32_t rom_base);

/**
 * Write a byte of `data` to the given `byte_addr` in the flash device
 * at `rom_base`.
 *
 * Note that the `byte_addr` is **not** a global address - it is the
 * local device address of the byte relative to the start of the chip.
 *
 * The sector containing the given `byte_addr` **must** be fully erased
 * before being written to (e.g. with the `sst_sector_erase` function).
 *
 * Normal reads will be unavailable during this call, and the
 * device will be erased afterward (assuming success).
 *
 * If the flash you're writing to the system ROM, you should disable
 * interrupts and avoid any calls that rely on the system TRAPs
 * until you have a valid ROM again!
 */
bool sst_write_byte(uint32_t rom_base, uint32_t byte_addr, uint8_t data);

/**
 * Send a raw top-level command.
 *
 * Depending on the command sent, the flash may be
 * unreadable after this call (until the command is completed).
 *
 * This will usually be followed by further writes to perform various
 * tasks, depending on the command sent.
 *
 * See https://ww1.microchip.com/downloads/en/DeviceDoc/20005022C.pdf
 * for valid command sequences.
 */
bool sst_command(uint32_t rom_base, SST_COMMAND command);

#endif//__ROSCO_M68K_SST_H__
