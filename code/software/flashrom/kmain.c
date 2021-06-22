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
 * Tech demo; Programmatic access to SST39SF0x0 Flash EEPROM
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <stdint.h>
#include <machine.h>
#include "sst.h"

#define EROM_BASE   0x00e00000
#define OROM_BASE   0x00e00001

typedef struct {
    uint8_t     manufacturer;
    uint8_t     device;
} SST;

void get_device_info(uint32_t rom_base, SST* sst) {
    sst_command(rom_base, SST_CMD_IDENTER);

    // Very limited as to what we can do here, with no ROM support...
    sst->manufacturer = sst_read_manufacturer_id(rom_base);
    sst->device = sst_read_device_id(rom_base);

    // ROM should be available again max 150ns after this is done    
    sst_command(rom_base, SST_CMD_IDEXIT);
}

const char* get_manufacturer_name(uint8_t mfr) {
    switch (mfr) {
    case SST_MFR_SST:
        return "SST";
    default:
        return "???";
    }
}

const char* get_device_name(uint8_t dev) {
    switch (dev) {
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

void kmain() {
    printf("\nrosco_m68k Flash EEPROM identifier / write POC\n");
    printf("**********************************************\n\n");

    mcDisableInterrupts();      // ROM is about to become unavailable, so no interrupts!

    SST even, odd;

    get_device_info(EROM_BASE, &even);
    get_device_info(OROM_BASE, &odd);

    mcEnableInterrupts();       // ROM should be back now, so re-enable interrupts.

    printf("EVEN ROM is %s [Manufacturer %s]\n", 
            get_device_name(even.device), get_manufacturer_name(even.manufacturer));
    printf("ODD  ROM is %s [Manufacturer %s]\n", 
            get_device_name(odd.device), get_manufacturer_name(odd.manufacturer));
}

