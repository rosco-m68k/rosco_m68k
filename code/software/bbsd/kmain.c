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
 * Demo/POC for SD card lib
 * ------------------------------------------------------------
 */

#include <stdio.h>
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

typedef void (*loadedfunc)();

uint8_t *loadptr = (void*)0x28000;
loadedfunc entryPoint = (loadedfunc)0x28000;

static BBSPI spi;
static BBSDCard sd;
static BlockDevice block_device;

int media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    if (!block_device.initialized) {
        return 0;
    }

    for(int i = 0; i < sector_count; i++) {
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

void kmain() {
    if (BBSPI_initialize(&spi, CS, SCK, MOSI, MISO)) {
        if (BBSD_initialize(&sd, &spi)) {

            switch (sd.type) {
            case BBSD_CARD_TYPE_V1:
                printf("Found SD v1 card ");
                break;
            case BBSD_CARD_TYPE_V2:
                printf("Found SD v2 card ");
                break;
            case BBSD_CARD_TYPE_SDHC:
                printf("Found SDHC card ");
                break;
            default:
                printf("Found unknown card type ");
            }
#ifndef SD_MINIMAL
#ifdef _ROSCOM68K_STDIO_H
            uint32_t size = BBSD_get_size(&sd);
            printf("with %d block(s)\r\n", size);
#endif
#else
            printf("(Size unknown in minimal configuration)\r\n");
#endif

            if (BBSD_make_device(&sd, &block_device)) {
                fl_attach_media(media_read, media_write);

                void *file = fl_fopen("/ROSCODE1.BIN", "r");

                if (file != NULL) {
                    printf("Loading...\r\n");

                    int c;
                    while ((c = fl_fread(loadptr, 512, 1, file)) != EOF) {
                        loadptr += c;
                    }

                    fl_fclose(file);

                    entryPoint();
                } else {
                    printf("Open failed\r\n");
                }

            } else {
                printf("BlockDevice failed to initialize");
            }
        }
    } else {
        printf("SPI init failed\r\n");
    }

    printf("Game Over; Rebooting...\r\n");
}
