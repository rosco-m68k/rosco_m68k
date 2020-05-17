/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v1
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * SD Card loader for stage 2
 * ------------------------------------------------------------
 */

#include <stdnoreturn.h>
#include <stdbool.h>
#include <stdint.h>
#include <gpio.h>

#include "bbspi.h"
#include "bbsd.h"
#include "device/block.h"
#include "fat_filelib.h"

#define CS      GPIO1
#define SCK     GPIO2
#define MOSI    GPIO3
#define MISO    GPIO4

#ifdef _PRINTF_H_
#include <basicio.h>
#define printf_(stuff)   mcPrint(stuff)
#endif

extern void mcPrint(char *str);
extern void print_unsigned(uint32_t num, uint8_t base);

extern uint8_t *kernel_load_ptr;

static BBSPI spi;
static BBSDCard sd;
static BlockDevice block_device;

int media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    if (!block_device.initialized) {
        return 0;
    }

    for(uint32_t i = 0; i < sector_count; i++) {
        if (!block_device.readBlock(&block_device, sector, buffer)) {
            return 0;
        }
        buffer += block_device.getBlockSize(&block_device);
    }

    return 1;
}

int media_write(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    return 0;
}

bool load_kernel() {
    if (BBSPI_initialize(&spi, CS, SCK, MOSI, MISO)) {
        if (BBSD_initialize(&sd, &spi)) {

            switch (sd.type) {
            case BBSD_CARD_TYPE_V1:
                mcPrint("Found SD v1 card\r\n");
                break;
            case BBSD_CARD_TYPE_V2:
                mcPrint("Found SD v2 card\r\n");
                break;
            case BBSD_CARD_TYPE_SDHC:
                mcPrint("Found SDHC card\r\n");
                break;
            default:
                mcPrint("Found unknown card type\r\n");
            }

            if (BBSD_make_device(&sd, &block_device)) {
                fl_attach_media(media_read, media_write);

                void *file = fl_fopen("/ROSCODE1.BIN", "r");

                if (file != NULL) {
                    mcPrint("Loading");

                    int c;
                    uint8_t b = 0;
                    while ((c = fl_fread(kernel_load_ptr, 512, 1, file)) != EOF) {
                        kernel_load_ptr += c;
                        if (++b == 10) {
                          mcPrint(".");
                          b = 0;
                        }
                    }

                    mcPrint(" Complete\r\n");

                    fl_fclose(file);

                    return true;
                } else {
                    mcPrint("Open failed\r\n");
                }

            } else {
                mcPrint("BlockDevice failed to initialize");
            }
        }
    } else {
        mcPrint("SPI init failed\r\n");
    }

    return false;
}
