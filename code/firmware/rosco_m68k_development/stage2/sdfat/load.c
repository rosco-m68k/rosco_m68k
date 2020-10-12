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
#include <bbsd.h>
#include "fat_filelib.h"

#define CS      GPIO1
#define SCK     GPIO2
#define MOSI    GPIO3
#define MISO    GPIO4

#define BUF_LEN 82
#define BUF_MAX BUF_LEN - 2

extern void mcPrint(char *str);
extern bool BBSD_support_check();

extern uint8_t *kernel_load_ptr;

static uint8_t buf[BUF_LEN];
static BBSDCard sd;

// TODO use SDB properly, this address might change in future!
static volatile uint32_t * const upticks = (volatile uint32_t * const)0x40C;

int media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    if (!sd.initialized) {
        return 0;
    }

    for(uint32_t i = 0; i < sector_count; i++) {
        if (!BBSD_read_block(&sd, sector, buffer)) {
            return 0;
        }
        buffer += 512;
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
    if (!BBSD_support_check()) {
        mcPrint("Warning: No SD support in ROM - This may indicate your ROMs are not built correctly!\r\n");
        return false;
    }

    if (BBSD_initialize(&sd) == BBSD_INIT_OK) {
        switch (sd.type) {
        case BBSD_CARD_TYPE_V1:
            mcPrint("Found SD v1 card; ");
            break;
        case BBSD_CARD_TYPE_V2:
            mcPrint("Found SD v2 card; ");
            break;
        case BBSD_CARD_TYPE_SDHC:
            mcPrint("Found SDHC card; ");
            break;
        default:
            mcPrint("Found unknown card type ");
        }

        fl_attach_media(media_read, media_write);

        void *file = fl_fopen("/ROSCODE1.BIN", "r");

        if (file != NULL) {
            uint32_t start = *upticks;

            mcPrint("Loading");

            int c;
            uint8_t *current_load_ptr = kernel_load_ptr;
            uint8_t b = 0;
            while ((c = fl_fread(current_load_ptr, 512, 1, file)) > 0) {
                current_load_ptr += c;
                if (++b == 16) {
                    mcPrint(".");
                    b = 0;
                }
            }

            fl_fclose(file);

            if (c != EOF) {
                mcPrint("\r\n*** SD load error\r\n\r\n");
            } else {
                uint32_t total_ticks = *upticks - start;
                uint32_t total_secs = (total_ticks + 50) / 100;
                uint32_t load_size = current_load_ptr - kernel_load_ptr;
                mcPrint("\r\nLoaded ");
                print_unsigned(load_size, 10);
                mcPrint(" bytes in ~");
                print_unsigned(total_secs ? total_secs : 1, 10);
                mcPrint(" seconds\r\n");

                return true;
            }
        } else {
            mcPrint("Open failed\r\n");
        }
    }

    return false;
}
