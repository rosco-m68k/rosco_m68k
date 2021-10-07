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
#include <stdbool.h>

#include <basicio.h>
#include <machine.h>
#include <sst_flash.h>

#define ROM_BASE    0x00e00000
#define EROM_BASE   ((ROM_BASE))
#define OROM_BASE   ((ROM_BASE + 1))

#define CONFIG_SECT ((0x7f))
#define ROM_COUNT   2
#define CONFIG_SIZE ((SST_SECT_SIZE * ROM_COUNT))

#define CONFIG_ADDR ((ROM_BASE + (CONFIG_SECT * SST_SECT_SIZE * ROM_COUNT)))

typedef struct {
    uint32_t data[CONFIG_SIZE / 4];
} ConfigData;

static volatile ConfigData *config = (ConfigData*)CONFIG_ADDR;
static ConfigData new_config_buf;

static bool write_config_area(void *buffer) {
    bool result = buffer == NULL;

    uint8_t intr_mask = mcDisableInterrupts();  // ROM is about to become unavailable, so no interrupts!

    if (!sst_sector_erase(EROM_BASE, CONFIG_SECT)) {
        goto finally;
    }

    if (!sst_sector_erase(OROM_BASE, CONFIG_SECT)) {
        goto finally;
    }

    uint8_t *cbuf = (uint8_t*)buffer;
    uint32_t start_byte = CONFIG_SECT * SST_SECT_SIZE;

    for (int i = 0; i < SST_SECT_SIZE; i++) {
        // Write even ROM
        if (!sst_write_byte(EROM_BASE, start_byte + i, cbuf[i << 1])) {
            goto finally;
        }

        // Write odd ROM
        if (!sst_write_byte(OROM_BASE, start_byte + i, cbuf[(i << 1) | 1])) {
            goto finally;
        }
    }

    result = true;

finally:
    mcEnableInterrupts(intr_mask);              // ROM should be back now, so re-enable interrupts.
    return result;
}

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;

    printf("\nrosco_m68k Flash EEPROM identifier / write POC\n");
    printf("**********************************************\n\n");

    uint8_t intr_mask = mcDisableInterrupts();  // ROM is about to become unavailable, so no interrupts!

    SSTDeviceId even, odd;

    sst_get_device_info(EROM_BASE, &even);
    sst_get_device_info(OROM_BASE, &odd);

    mcEnableInterrupts(intr_mask);              // ROM should be back now, so re-enable interrupts.

    printf("EVEN ROM is %s [Manufacturer %s]\n", 
            sst_get_device_name(&even), sst_get_manufacturer_name(&even));
    printf("ODD  ROM is %s [Manufacturer %s]\n", 
            sst_get_device_name(&odd), sst_get_manufacturer_name(&odd));

    printf("\nConfig area is 1 sector per ROM (%d total)\n", ROM_COUNT);
    printf("  Sector num : 0x%02x\n", CONFIG_SECT);
    printf("  Sector size: %d bytes\n", SST_SECT_SIZE);
    printf("  Total size : %d bytes\n", CONFIG_SIZE);
    printf("  Base addr  : 0x%08x\n", CONFIG_ADDR);

    printf("\nOld data: 0x%08lx 0x%08lx 0x%08lx...\n", config->data[0], config->data[1], config->data[2]);

    uint32_t new_data;
    if (config->data[0] == 0x55AA55AA) {
        new_data = 0xAA55AA55;
    } else {
        new_data = 0x55AA55AA;
    }

    for (int i = 0; i < CONFIG_SIZE / 4; i++) {
        new_config_buf.data[i] = new_data;
    }

    if (!write_config_area(&new_config_buf)) {
        printf("Failed to write config area!\n");
    } else {
        printf("New data: 0x%08lx 0x%08lx 0x%08lx...\n", config->data[0], config->data[1], config->data[2]);
    }

    printf("(Press a key)\n");
    readchar();

    return 0;
}

