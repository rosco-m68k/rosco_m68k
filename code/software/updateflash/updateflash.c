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
 * Tech demo; Upgrade (or downgrade) rosco_m68k flash ROM
 * firmware using sst_flash library.
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <machine.h>
#include <sst_flash.h>
#include <sdfat.h>
#include <machine.h>

#define ROM_BASE    0x00e00000
#define EROM_BASE   ((ROM_BASE))
#define OROM_BASE   ((ROM_BASE + 1))

extern void *_end;
extern void reboot_to_init();

// NB Size must be even (this is checked before calling this function).
static bool write_boot_rom(void *buffer, uint32_t size) {
    bool result = false;
    uint8_t next_sector = 0;
    int half_size = size / 2;
    uint8_t *cbuf = (uint8_t*)buffer;

    for (int i = 0; i < half_size; i++) {
        if (i % SST_SECT_SIZE == 0) {
            if (!sst_sector_erase(EROM_BASE, next_sector)) {
                goto finally;
            }

            if (!sst_sector_erase(OROM_BASE, next_sector)) {
                goto finally;
            }

            next_sector += 1;
        }

        // Write even ROM
        if (!sst_write_byte(EROM_BASE, i, cbuf[i << 1])) {
            goto finally;
        }

        // Write odd ROM
        if (!sst_write_byte(OROM_BASE, i, cbuf[(i << 1) | 1])) {
            goto finally;
        }
    }

    result = true;

finally:
    return result;
}

static uint32_t get_logical_rom_size(SSTDeviceId *even, SSTDeviceId *odd) {
    uint32_t romsize = 0;

    switch (even->device) {
    case SST_DEV_010A:
        romsize = 262144;
        break;
    case SST_DEV_020A:
        romsize = 524288;
        break;
    case SST_DEV_040:
        romsize = 1048576;
        break;
    }

    if (even->device != odd->device) {
        switch(odd->device) {
        case SST_DEV_010A:
            romsize = 262144;
            break;
        case SST_DEV_020A:
            if (romsize > 524288) {
                romsize = 524288;
            }
            break;
        case SST_DEV_040:
            // Must already be smaller than this...
            break;
        }
    }

    return romsize;
}

// N.B. relies on sector size being a power of 2, which seems a reasonable assumption...
// Thanks to https://stackoverflow.com/a/9194117
static int calculate_sector_count(int file_size) {
    return (file_size + SST_SECT_SIZE - 1) & -SST_SECT_SIZE;
}

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    char c;

    SSTDeviceId even, odd;
    uint8_t *buffer = (uint8_t*)&_end;
    uint32_t buffer_size = _SDB_MEM_SIZE - (uint32_t)buffer - 2048;     // Randomly choosing 2k for stack...

    printf("\nrosco_m68k Flash EEPROM Update Utility\n");
    printf("**********************************************\n\n");

    uint8_t intr_mask = mcDisableInterrupts();  // ROM is about to become unavailable, so no interrupts!

    sst_get_device_info(EROM_BASE, &even);
    sst_get_device_info(OROM_BASE, &odd);

    mcEnableInterrupts(intr_mask);              // ROM should be back now, so re-enable interrupts.

    printf("EVEN ROM is %s [Manufacturer: %s]\n",
            sst_get_device_name(&even), sst_get_manufacturer_name(&even));
    printf("ODD  ROM is %s [Manufacturer: %s]\n",
            sst_get_device_name(&odd), sst_get_manufacturer_name(&odd));

    uint32_t logical_romsize = get_logical_rom_size(&even, &odd);

    if (logical_romsize == 0) {
        printf("Apologies, but ROMs don't appear to be SST flash, this utility cannot program them.\n");
    } else {
        printf("\nLogical ROM size is %ld bytes\n", logical_romsize);
        printf("%ld bytes available for update file buffer\n\n", buffer_size);

        if (!SD_check_support()) {
            printf("Sorry, SD Card support is required in ROM, but is not present. Cannot read firmware update files.\n");
        } else {

            do {
                printf("\n>>> Insert SD Card with \"rosco_m68k.rom\" update file and press ENTER :");
                c = mcReadchar();
            } while ( c != '\r');

            printf("\n\nChecking SD Card...\n");

            if (!SD_FAT_initialize()) {
                printf("Sorry, no readable (FAT) SD card detected. Cannot read firmware update file.\n");
            } else {
                FL_FILE *romfile = fl_fopen("/rosco_m68k.rom", "R");

                if (romfile == NULL) {
                    printf("Sorry, no firmware update found. Ensure `rosco_m68k.rom` exists in the root directory\n");
                } else {
                    fl_fseek(romfile, 0L, SEEK_END);
                    uint32_t upgrade_romsize = fl_ftell(romfile);
                    fl_fseek(romfile, 0L, SEEK_SET);

                    if (upgrade_romsize == 0 || fl_ftell(romfile) != 0) {
                        printf("File size is 0 or seek failed; I'm afraid I can't safely continue.\n");
                    } else if (upgrade_romsize > logical_romsize) {
                        printf("Apologies, but update is too large for logical ROM, cannot flash\n");
                    } else if (upgrade_romsize > buffer_size) {
                        printf("Sorry, update ROM cannot fit in available memory, and I cannot stream it yet. Cannot continue.\n");
                        printf("(FYI, max update size with current memory configuration is %ld bytes\n)", buffer_size);
                    } else if ((upgrade_romsize & 1) == 1) {
                        printf("Sorry, but upgrade file size is odd, assuming invalid image. Cannot continue.\n");
                    } else {
                        printf("Found an update ROM of %ld bytes, Will attempt to flash :)\n", upgrade_romsize);
                        printf("Reading file...");

                        if (fl_fread(buffer, 1, upgrade_romsize, romfile) != (int)upgrade_romsize) {
                            printf(" failed :( ... Cannot continue with incomplete image...\n");
                        } else {
                            printf(" success; Checking version...\n");
                            
                            RomVersionInfo *version_info = (RomVersionInfo*)(buffer + 0x400);

                            if (version_info->major != 0) {
                                printf("ROM image indicates version %2d.%2d.%s ; Extended system data area: %s\n", 
                                        version_info->major, version_info->minor,
                                        version_info->is_snapshot ? "SNAPSHOT" : "RELEASE",
                                        version_info->is_extdata ? "Required" : "Not required");

                                if (version_info->is_huge) {                                    
                                    printf(" success!\n\n");
                                    printf("Ready to flash your rosco_m68k. This process should only take a few seconds.\n");
                                    printf("\n\nNo flashing lights is normal - DO NOT TURN OFF YOUR rosco_m68k!\n\n");
                                    printf("After the update is complete, your rosco_m68k should reboot automatically using\n");
                                    printf("the newly updated flash.\n");

                                    printf("\n>>> If you ready to proceed, press \"Y\" now :");

                                    char c = mcReadchar();
                                    if (c != 'Y' && c != 'y')
                                    {
                                        printf("\n\nUpdate NOT started, exiting.\n");
                                        return 0;
                                    }

                                    printf("\n\n\n  *** rosco_m68k flash update in progress ***\n\n");
                                    printf("        DO NOT TURN OFF YOUR rosco_m68k!\n\n");

                                    mcBusywait(5000 * 500);  // small delay to allow user to see message...

                                    mcDisableInterrupts();  // ROM is about to become unavailable, so no interrupts!

                                    if (!write_boot_rom(buffer, upgrade_romsize)) {
                                        printf("Oh dear, flash failed. \n");
                                        printf("Honestly, it's a miracle you're even seeing this message...\n");
                                        printf("Trying a reboot, if this fails you may need to reflash your ROMs in an external programmer :(\n");
                                    } else {
                                        // Cannot print anything here as EFPs may have been moved, or may not exist at all any more.
                                        // Just try rebooting instead...
                                        reboot_to_init();
                                    }
                                } else {
                                    printf("ROM does not appear to be a flashable image (i.e. not a HUGEROM build). Cannot continue\n");
                                }
                            } else {
                                printf("Oops, version check failed; Quitting while we're ahead...\n");
                            } 
                        }
                    }

                    fl_fclose(romfile);
                }
            }
        }
    }

    return 0;
}

