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
 * Interface to the firmware SD Card support
 * ------------------------------------------------------------
 */

#ifndef ROSCO_M68K_SDFAT_H
#define ROSCO_M68K_SDFAT_H

#include <stdbool.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "fat_filelib.h"

typedef enum {
    SD_CARD_TYPE_V1,
    SD_CARD_TYPE_V2,
    SD_CARD_TYPE_SDHC,
    SD_CARD_TYPE_UNKNOWN,
} SDCardType;

typedef enum {
    SD_INIT_OK,
    SD_INIT_IDLE_FAILED,
    SD_INIT_CMD8_FAILED,
    SD_INIT_ACMD41_FAILED,
} SDInitStatus;

typedef struct {
    bool            initialized;
    SDCardType      type;
    uint32_t        reserved[4];
} SDCard;

typedef struct {
  // 0x0
  unsigned csd_ver : 2;
  unsigned reserved1 : 6;
  // 0x1
  uint8_t taac;
  // 0x2
  uint8_t nsac;
  // 0x3
  uint8_t tran_speed;
  // 0x4
  uint8_t ccc_high;
  // 0x5
  unsigned ccc_low : 4;
  unsigned read_bl_len : 4;
  // 0x6
  unsigned read_bl_partial : 1;
  unsigned write_blk_misalign : 1;
  unsigned read_blk_misalign :1;
  unsigned dsr_imp : 1;
  unsigned reserved2 : 2;
  unsigned c_size_high : 2;
  // 0x7
  uint8_t c_size_mid;
  // 0x8
  unsigned c_size_low :2;
  unsigned vdd_r_curr_min : 3;
  unsigned vdd_r_curr_max : 3;
  // 0x9
  unsigned vdd_w_curr_min : 3;
  unsigned vdd_w_cur_max : 3;
  unsigned c_size_mult_high : 2;
  // 0xA
  unsigned c_size_mult_low : 1;
  unsigned erase_blk_en : 1;
  unsigned sector_size_high : 6;
  // 0xB
  unsigned sector_size_low : 1;
  unsigned wp_grp_size : 7;
  // 0xC
  unsigned wp_grp_enable : 1;
  unsigned reserved3 : 2;
  unsigned r2w_factor : 3;
  unsigned write_bl_len_high : 2;
  // 0xD
  unsigned write_bl_len_low : 2;
  unsigned write_bl_partial : 1;
  unsigned reserved4 : 5;
  // 0xE
  unsigned file_format_grp : 1;
  unsigned copy : 1;
  unsigned perm_write_protect : 1;
  unsigned tmp_write_protect : 1;
  unsigned file_format : 2;
  unsigned reserved5: 2;
  // 0xF
  unsigned crc : 7;
  unsigned always1 : 1;
} __attribute__ ((packed)) SDCard_CSD1;

//------------------------------------------------------------------------------
// CSD for version 2.00 cards
typedef struct {
  // 0x0
  unsigned csd_ver : 2;
  unsigned reserved1 : 6;
  // 0x1
  uint8_t taac;
  // 0x2
  uint8_t nsac;
  // 0x3
  uint8_t tran_speed;
  // 0x4
  uint8_t ccc_high;
  // 0x5
  unsigned ccc_low : 4;
  unsigned read_bl_len : 4;
  // 0x6
  unsigned read_bl_partial : 1;
  unsigned write_blk_misalign : 1;
  unsigned read_blk_misalign :1;
  unsigned dsr_imp : 1;
  unsigned reserved2 : 4;
  // 0x7
  unsigned reserved3 : 2;
  unsigned c_size_high : 6;
  // 0x8
  uint8_t c_size_mid;
  // 0x9
  uint8_t c_size_low;
  // 0xA
  unsigned reserved4 : 1;
  unsigned erase_blk_en : 1;
  unsigned sector_size_high : 6;
  // 0xB
  unsigned sector_size_low : 1;
  unsigned wp_grp_size : 7;
  // 0xC
  unsigned wp_grp_enable : 1;
  unsigned reserved5 : 2;
  unsigned r2w_factor : 3;
  unsigned write_bl_len_high : 2;
  // 0xD
  unsigned write_bl_len_low : 2;
  unsigned write_bl_partial : 1;
  unsigned reserved6 : 5;
  // 0xE
  unsigned file_format_grp : 1;
  unsigned copy : 1;
  unsigned perm_write_protect : 1;
  unsigned tmp_write_protect : 1;
  unsigned file_format : 2;
  unsigned reserved7: 2;
  // 0xF
  unsigned crc : 7;
  unsigned always1 : 1;
} __attribute__ ((packed)) SDCard_CSD2;

typedef union {
  SDCard_CSD1 v1;
  SDCard_CSD2 v2;
} SDCard_CSD;



/*** The first two routines should be good enough for common use *** */

/**
 * Check whether SD Card support is present in the current firmware.
 *
 * You should do this before using any of the other routines!
 */
bool SD_check_support();

/**
 * Initialize the SD Card, and set up the FAT file library with sensible 
 * defaults.
 */
bool SD_FAT_initialize();

/**
 * Get the default SD Card used by the FAT libs by default,
 * or NULL if it hasn't been initialized (with a call to 
 * SD_FAT_initialize()). 
 */
SDCard* SD_FAT_get_sd_card();


/*** The following routines are lower-level and allow finer control *** */

/**
 * Attempt to initialize the SD card, populating the supplied SDCard struct.
 */
SDInitStatus SD_initialize(SDCard *sd);

/**
 * Attempt to read a block from the SD card.
 */ 
bool SD_read_block(SDCard *sd, uint32_t block, void *buf);

/**
 * Attempt to write a block from the SD card.
 */
bool SD_write_block(SDCard *sd, uint32_t block, void *buf);

/**
 * Attempt to read an SD card register into the supplied buffer.
 */
bool SD_read_register(SDCard *sd, uint8_t regcmd, void *buf);

/**
 * Attempt to read the CSD register into the supplied struct.
 */
bool SD_get_csd(SDCard *sd, SDCard_CSD *csd);

/** 
 * Attempt to determine the size of the connected SD card.
 */
uint32_t SD_get_size(SDCard *sd);

#endif

