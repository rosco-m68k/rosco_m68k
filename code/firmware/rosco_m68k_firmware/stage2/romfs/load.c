/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2021-2022 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * IDE HDD loader for stage 2
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include "machine.h"
#include "lfs.h"

// TODO this is hardcoded to 360KB, needs to support 1440 (for 720KB) too...
//
// Should be linker-provided really...
#ifndef ROMFS_BASE
#define ROMFS_BASE          ((0x00E26000))
#endif
#ifndef ROMFS_BLOCKSIZE
#define ROMFS_BLOCKSIZE     ((512))
#endif
#ifndef ROMFS_BLOCKS
#define ROMFS_BLOCKS        ((720))
#endif
#ifndef ROMFS_CACHE_SIZE
#define ROMFS_CACHE_SIZE    ((512))
#endif
#ifndef ROMFS_READ_SIZE
#define ROMFS_READ_SIZE     ((512))
#endif
#ifndef ROMFS_PROG_SIZE
#define ROMFS_PROG_SIZE     ((512))
#endif
#ifndef ROMFS_LA_SIZE
#define ROMFS_LA_SIZE       ((512))
#endif

#ifdef LFS_DEBUGGING
#include <stdio.h>
#define debugf(...)         printf(__VA_ARGS__)
#else
#define debugf(...)         ((void)(0))
#endif

extern uint8_t *kernel_load_ptr;

static int romfs_device_read(const struct lfs_config *c, lfs_block_t block, lfs_off_t off, void *buffer, lfs_size_t size) {
    uint8_t *addr = (uint8_t*)(ROMFS_BASE + (block * c->block_size) + off);

    debugf("ROMFS: Read block %ld / ofs %ld [ %ld bytes ] - base addr is %p - target is %p", block, off, size, addr, buffer);

    // TODO check this can handle odd-offsets...
    memcpy(buffer, addr, size);

    debugf(" [DONE]\n");

    return LFS_ERR_OK;
}

int romfs_device_prog(const struct lfs_config *c, lfs_block_t block, lfs_off_t off, const void *buffer, lfs_size_t size) {
    debugf("PROG CALLED\n");
    return LFS_ERR_OK;
}

int romfs_device_erase(const struct lfs_config *c, lfs_block_t block) {
    debugf("ERASE CALLED\n");
    return LFS_ERR_OK;
}

int romfs_device_sync(const struct lfs_config *c) {
    debugf("SYNC CALLED\n");
    return LFS_ERR_OK;
}

static uint8_t prog_buffer[ROMFS_PROG_SIZE];
static uint8_t read_buffer[ROMFS_READ_SIZE];
static uint8_t lookahead_buffer[ROMFS_LA_SIZE];

static inline void zero_stuff(lfs_t *lfs, struct lfs_config *cfg, lfs_file_t *file, struct lfs_file_config *file_cfg) {
    memset(lfs, 0, sizeof(lfs_t));
    memset(cfg, 0, sizeof(struct lfs_config));
    memset(file, 0, sizeof(lfs_file_t));
    memset(file_cfg, 0, sizeof(struct lfs_file_config));
    memset(lfs, 0, sizeof(lfs_t));
}

static inline void set_config(struct lfs_config *cfg) {
    // block device operations
    cfg->read  = romfs_device_read;
    cfg->prog = romfs_device_prog;
    cfg->erase = romfs_device_erase;
    cfg->sync = romfs_device_sync;

    // block device configuration
    cfg->read_size = ROMFS_READ_SIZE;
    cfg->prog_size = ROMFS_PROG_SIZE;
    cfg->block_size = ROMFS_BLOCKSIZE;
    cfg->block_count = ROMFS_BLOCKS;
    cfg->cache_size = ROMFS_CACHE_SIZE;
    cfg->lookahead_size = ROMFS_LA_SIZE;
    cfg->block_cycles = 500;
    cfg->read_buffer = read_buffer;
    cfg->prog_buffer = prog_buffer;
    cfg->lookahead_buffer = lookahead_buffer;
}

static bool try_boot(void *addr) {
    lfs_t lfs;
    struct lfs_config cfg;
    lfs_file_t file;
    struct lfs_file_config file_cfg;
    uint8_t cache[ROMFS_CACHE_SIZE];

    zero_stuff(&lfs, &cfg, &file, &file_cfg);
    set_config(&cfg);
    file_cfg.buffer = cache;

    debugf("ROMFS Init:");
    int err = lfs_mount(&lfs, &cfg);
    if (err != LFS_ERR_OK) {
        debugf("  No mount: %d\n", err);
        return false;
    }

    debugf("  Looks good\r\n");

    err = lfs_file_opencfg(&lfs, &file, "/ROSCODE1.BIN", LFS_O_RDONLY, &file_cfg);
    if (err != LFS_ERR_OK) {
        debugf("  No open: %d\n", err);
        return false;
    }
    
    FW_PRINT_C("Found bootable ROMFS");

    lfs_soff_t size = lfs_file_size(&lfs, &file);
    if (size < 0) {
        FW_PRINT_C(", but failed to read, skipping it.\r\n");
        return false;
    }

    debugf("Got size, is %ld\n", size);

    lfs_ssize_t actual = lfs_file_read(&lfs, &file, kernel_load_ptr, size);
    lfs_file_close(&lfs, &file);
    lfs_unmount(&lfs);    

    if (actual != size) {
        debugf(" [read: %ld but expected %ld ] ", actual, size);
        FW_PRINT_C(", but failed to read, skipping it.\r\n");
        return false;        
    }

    FW_PRINT_C(" - booting it.\r\n");

    return true;
}

bool romfs_load_kernel(void) {
    return try_boot((void*)ROMFS_BASE);
}

