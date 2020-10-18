/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|      libraries v1                 
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Additional SD support routines 
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>
#include <sdfat.h>
#include <stdio.h>

bool SD_get_csd(SDCard *sd, SDCard_CSD *csd) {
    return SD_read_register(sd, 9, (void*) csd);
}

uint32_t SD_get_size(SDCard *sd) {
    static SDCard_CSD csdbuf;

    if (!SD_get_csd(sd, &csdbuf)) {
        return 0;
    }
    if (csdbuf.v1.csd_ver == 0) {
        uint8_t read_bl_len = csdbuf.v1.read_bl_len;
        uint16_t c_size = (csdbuf.v1.c_size_high << 10)
                | (csdbuf.v1.c_size_mid << 2) | csdbuf.v1.c_size_low;
        uint8_t c_size_mult = (csdbuf.v1.c_size_mult_high << 1)
                | csdbuf.v1.c_size_mult_low;

        return (uint32_t) (c_size + 1) << (c_size_mult + read_bl_len - 7);
    } else if (csdbuf.v2.csd_ver == 1) {
        uint32_t c_size = ((uint32_t) csdbuf.v2.c_size_high << 16)
                | (csdbuf.v2.c_size_mid << 8) | csdbuf.v2.c_size_low;

        return (c_size + 1) << 10;
    } else {
        return 0;
    }
}

static SDCard sdcard;

static int FAT_media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    for(int i = 0; i < sector_count; i++) {
        if (!SD_read_block(&sdcard, sector + i, buffer)) {
            return 0;
        }
        buffer += 512;
    }

    return 1;
}

static int FAT_media_write(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    for(int i = 0; i < sector_count; i++) {
        if (!SD_write_block(&sdcard, sector + i, buffer)) {
            return 0;
        }
        buffer += 512;
    }

    return 1;
}


bool SD_FAT_initialize() {
    if (SD_initialize(&sdcard) != SD_INIT_OK) {
        return false;
    }

    if (fl_attach_media(FAT_media_read, FAT_media_write) != FAT_INIT_OK) {
        return false;
    } else {  
        return true;
    }
}

SDCard* SD_FAT_get_sd_card() {
  if (sdcard.initialized) {
    return &sdcard;
  } else {
    return NULL;
  }
}
