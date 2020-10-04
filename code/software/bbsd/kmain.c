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
#include <machine.h>
#include <gpio.h>

#include "bbspi.h"
#include "bbsd.h"
#include "device/block.h"
#include "fat_access.h"
#include "fat_filelib.h"

#define CS      GPIO1
#define SCK     GPIO2
#define MOSI    GPIO3
#define MISO    GPIO4

// #ifdef SD_MINIMAL
// #ifdef _PRINTF_H_
// #include <basicio.h>
// #define printf_(stuff)   mcPrint(stuff)
// #endif
// #endif


// timer helpers
static uint32_t start_tick;
void timer_start()
{
  uint32_t ts = _TIMER_100HZ;
  uint32_t t;
  while ((t = _TIMER_100HZ) == ts)
    ;
  start_tick = t;
}

uint32_t timer_stop()
{
  uint32_t stop_tick = _TIMER_100HZ;

  return (stop_tick - start_tick) * 10;
}

// from https://stackoverflow.com/questions/21001659
unsigned int crc32b(unsigned char *message, int count)
{
  int i, j;
  unsigned int byte, crc, mask;

  crc = 0xFFFFFFFF;
  for (i = 0; i < count; i++)
  {
    byte = message[i]; // Get next byte.
    crc = crc ^ byte;
    for (j = 7; j >= 0; j--)
    { // Do eight times.
      mask = -(crc & 1);
      crc = (crc >> 1) ^ (0xEDB88320 & mask);
    }
  }
  return ~crc;
}


typedef void (*loadedfunc)();

uint8_t *loadstartptr = (void*)0x28000;
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
    mcDelaymsec10(100);
    printf("BBSD Test Starting...\n");

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
            printf("with %d block(s)\n", size);
#endif
#else
            printf("(Size unknown in minimal configuration)\n");
#endif

            if (BBSD_make_device(&sd, &block_device)) {
                fl_attach_media(media_read, media_write);

                printf("Opening \"ROSCODE1.BIN\"...\n");

                timer_start();
                void *file = fl_fopen("/ROSCODE1.BIN", "r");
                uint32_t open_time = timer_stop();

                if (file != NULL) {
                    printf("Open succeeded, time %d msec.\n", open_time);
                    printf("Reading \"ROSCODE1.BIN\"...\n");

                    int c;
                    uint8_t *loadptr = loadstartptr;
                    timer_start();
                    while ((c = fl_fread(loadptr, 512, 1, file)) != EOF) {
                        loadptr += c;
                    }

                    fl_fclose(file);
                    uint32_t load_time = timer_stop();

                    uint32_t bytes = loadptr - loadstartptr;
                    printf("Finished loading %d bytes (%0.02f KiB).\n", bytes, bytes / 1024.0f);
                    printf("Time % 0.03f seconds, Speed: % 0.02f KiB/sec.\n", load_time / 1000.0f, (bytes / 1024.0f) / (load_time / 1000.0f));
                    printf("Calculating CRC32...");
                    uint32_t crc = crc32b(loadstartptr, bytes);
                    printf(" = 0x%08X\n", crc);

                    entryPoint();
                } else {
                    printf("Open failed\n");
                }

            } else {
                printf("BlockDevice failed to initialize\n");
            }
        } else {
          printf("SD init failed\n");
        }
    } else {
        printf("SPI init failed\n");
    }

    printf("Game Over; Rebooting...\n");
}
