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
 * SST39SF0x0 Flash EEPROM interface library POC
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>

#define SST_UNLOCK_A1       ((0x00005555<<1))
#define SST_UNLOCK_D1       0xAA
#define SST_UNLOCK_A2       ((0x00002AAA<<1))
#define SST_UNLOCK_D2       0x55

#define SST_SUBCMD_SECERASE 0x30
#define SST_SUBCMD_CHPERASE 0x10

// Manufacturer constants
#define SST_MFR_SST         0xBF

// Device constants
#define SST_DEV_010A        0xB5
#define SST_DEV_020A        0xB6
#define SST_DEV_040         0xB7

typedef enum {
  SST_CMD_BYTEPROG  = 0xA0,
  SST_CMD_ERASE     = 0x80,
  SST_CMD_IDENTER   = 0x90,
  SST_CMD_IDEXIT    = 0xF0,
} SST_COMMAND;

/* Send first-level command */
bool sst_command(uint32_t rom_base, SST_COMMAND command);

/* Subcommands (only legal after CMD_ERASE has been sent) */
bool sst_subcommand_sector_erase(uint32_t rom_base, uint16_t sector);
bool sst_subcommand_chip_erase(uint32_t rom_base);

/* ID operations (only legal between CMD_IDENTER and CMD_IDEXIT) */
uint8_t sst_read_manufacturer_id(uint32_t rom_base);
uint8_t sst_read_device_id(uint32_t rom_base);

