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

#define BUF_LEN 82
#define BUF_MAX BUF_LEN - 2

extern void mcPrint(char *str);

extern uint8_t *kernel_load_ptr;

static uint8_t buf[BUF_LEN];
static BBSPI spi;
static BBSDCard sd;
static BlockDevice block_device;

// TODO use SDB properly, this address might change in future!
static volatile uint32_t * const upticks = (volatile uint32_t * const)0x40C;

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

static uint8_t digit(unsigned char digit) {
  if (digit < 10) {
    return (char)(digit + '0');
  } else {
    return (char)(digit - 10 + 'A');
  }
}

static void print_unsigned(uint32_t num, uint8_t base) {
  if (base < 2 || base > 36) {
    return;
  }

  unsigned char bp = BUF_MAX;

  if (num == 0) {
    buf[bp--] = '0';
  } else {
    while (num > 0) {
      buf[bp--] = digit(num % base);
      num /= base;
    }
  }

  mcPrint((char*)&buf[bp+1]);
}

bool load_kernel() {
    if (BBSPI_initialize(&spi, CS, SCK, MOSI, MISO)) {
        if (BBSD_initialize(&sd, &spi) == BBSD_INIT_OK) {
            switch (sd.type) {
            case BBSD_CARD_TYPE_V1:
                mcPrint("Found SD v1 card ");
                break;
            case BBSD_CARD_TYPE_V2:
                mcPrint("Found SD v2 card ");
                break;
            case BBSD_CARD_TYPE_SDHC:
                mcPrint("Found SDHC card ");
                break;
            default:
                mcPrint("Found unknown card type ");
            }

            if (BBSD_make_device(&sd, &block_device)) {
                fl_attach_media(media_read, media_write);

                void *file = fl_fopen("/ROSCODE1.BIN", "r");

                if (file != NULL) {
                    uint32_t start = *upticks;

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

                    uint32_t total_ticks = *upticks - start;
                    uint32_t total_secs = total_ticks / 200;
                    mcPrint(" Completed in ~");
                    print_unsigned(total_secs ? total_secs : 1, 10);
                    mcPrint(" seconds\r\n");

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
