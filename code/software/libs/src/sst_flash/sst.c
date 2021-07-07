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

#include "sst_flash.h"

#define SST_UNLOCK_A1       ((0x00005555<<1))
#define SST_UNLOCK_D1       0xAA
#define SST_UNLOCK_A2       ((0x00002AAA<<1))
#define SST_UNLOCK_D2       0x55

#define SST_SUBCMD_SECERASE 0x30
#define SST_SUBCMD_CHPERASE 0x10

static void write(uint32_t addr, uint8_t data) {
    volatile uint8_t *p = (uint8_t*)addr;
    *p = data;
}

static void wait(uint32_t addr) {
    volatile uint8_t *p = (uint8_t*)addr;

    uint8_t last = (*p) & 0x40;
    uint8_t this;

    while ((this = ((*p) & 0x40)) != last) {
        last = this;
    }
}

static void unlock(uint32_t rom_base) {
    write(rom_base | SST_UNLOCK_A1, SST_UNLOCK_D1);
    write(rom_base | SST_UNLOCK_A2, SST_UNLOCK_D2);
}

bool sst_command(uint32_t rom_base, SST_COMMAND command) {
    unlock(rom_base);

    write(rom_base | SST_UNLOCK_A1, command);

    // TODO Tida etc wait might be needed here. 
    // Guaranteed not needed on r1 @ 10MHz...
    
    return true;
}

bool sst_sector_erase(uint32_t rom_base, uint8_t sector) {
    if (!sst_command(rom_base, SST_CMD_ERASE)) {
        return false;
    } else {
        unlock(rom_base);
        write(rom_base | (sector << 13), SST_SUBCMD_SECERASE);
        wait(rom_base);
    }

    return true;
}

// TODO 
bool sst_chip_erase(uint32_t rom_base) {
    if (!sst_command(rom_base, SST_CMD_ERASE)) {
        return false;
    } else {
        unlock(rom_base);
        write(rom_base | SST_UNLOCK_A1, SST_SUBCMD_CHPERASE);
        wait(rom_base);
    }

    return true;
}

bool sst_write_byte(uint32_t rom_base, uint32_t byte_addr, uint8_t data) {
    if (!sst_command(rom_base, SST_CMD_BYTEPROG)) {
        return false;
    } else {
        write(rom_base | (byte_addr << 1), data);
        wait(rom_base);
    }

    return true;
}

static uint8_t read_manufacturer_id(uint32_t rom_base) {
    volatile uint8_t *p = (uint8_t*)rom_base;
    return *p;
}

static uint8_t read_device_id(uint32_t rom_base) {
    volatile uint8_t *p = (uint8_t*)(rom_base | 2);
    return *p;
}

void sst_get_device_info(uint32_t rom_base, SSTDeviceId* sst) {
    sst_command(rom_base, SST_CMD_IDENTER);

    // Very limited as to what we can do here, with no ROM support...
    sst->manufacturer = read_manufacturer_id(rom_base);
    sst->device = read_device_id(rom_base);

    // ROM should be available again max 150ns after this is done
    sst_command(rom_base, SST_CMD_IDEXIT);
}

const char* sst_get_manufacturer_name(SSTDeviceId *sst) {
    switch (sst->manufacturer) {
    case SST_MFR_SST:
        return "SST";
    default:
        return "???";
    }
}

const char* sst_get_device_name(SSTDeviceId *sst) {
    switch (sst->device) {
    case SST_DEV_010A:
        return "SST39SF010A";
    case SST_DEV_020A:
        return "SST39SF020A";
    case SST_DEV_040:
        return "SST39SF040 ";
    default:
        return " <Unknown> ";
    }
}

