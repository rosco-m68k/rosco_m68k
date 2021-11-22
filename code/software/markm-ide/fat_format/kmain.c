/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2020 Xark
 * MIT License
 *
 * Example SD card file menu
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <fat_format.h>

//#define FS_SECTORS 41943040     // 20GB
#define FS_SECTORS 2097152      // 1GB
//#define FS_SECTORS 4096           // 2MB
#define FS_NAME    "ROSCO68K"
extern bool HD_FAT_initialize();
extern int FAT_media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count);
extern int FAT_media_write(uint32_t sector, uint8_t *buffer, uint32_t sector_count);

// main SD Card Menu function
void kmain() {
    HD_FAT_initialize();

    struct fatfs fs;

    fs.disk_io.read_media = FAT_media_read;
    fs.disk_io.write_media = FAT_media_write;

    int r = fatfs_format_fat32(&fs, FS_SECTORS, FS_NAME);

    if (!r) {
        printf("Format failed: %d\n", r);
    }
}

