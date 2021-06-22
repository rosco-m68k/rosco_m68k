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

#include "sst.h"

static void write(uint32_t addr, uint8_t data) {
    uint8_t *p = (uint8_t*)addr;
    *p = data;
}

static void wait(uint32_t addr) {
    uint8_t *p = (uint8_t*)addr;

    uint8_t last = (*p) & 0x40;
    uint8_t this;

    while ((this = *p) != last) {
        last = this;
    }
}

bool sst_command(uint32_t rom_base, SST_COMMAND command) {
    write(rom_base | SST_UNLOCK_A1, SST_UNLOCK_D1);
    wait(rom_base);
    write(rom_base | SST_UNLOCK_A2, SST_UNLOCK_D2);
    wait(rom_base);
    write(rom_base | SST_UNLOCK_A1, command);
    wait(rom_base);

    // TODO Tida etc wait might be needed here. 
    // Guaranteed not needed on r1 @ 10MHz...
    
    return true;
}

// TODO 
bool sst_subcommand_sector_erase(uint32_t rom_base, uint16_t sector);

// TODO 
bool sst_subcommand_chip_erase(uint32_t rom_base);

uint8_t sst_read_manufacturer_id(uint32_t rom_base) {
    uint8_t *p = (uint8_t*)rom_base;
    return *p;
}

uint8_t sst_read_device_id(uint32_t rom_base) {
    uint8_t *p = (uint8_t*)(rom_base | 2);
    return *p;
}

