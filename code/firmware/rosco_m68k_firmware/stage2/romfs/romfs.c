/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2024 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * ROMFS filesystem interface
 * ------------------------------------------------------------
 */

#include "romfs.h"
#include "lfs.h"

#ifndef LFS_BLOCK_CYCLES
#define LFS_BLOCK_CYCLES        500
#endif

#ifdef DEBUG_ROMFS
#include <stdio.h>
#define debugf(...)         printf(__VA_ARGS__)
#else
#define debugf(...)         ((void)(0))
#endif

static int romfs_device_read(const struct lfs_config *cfg, lfs_block_t block, lfs_off_t off, void *buffer, lfs_size_t size) {
    ROMFS *romfs = (ROMFS*)cfg->context;
    uint8_t *addr = (uint8_t*)((uint8_t*)romfs->device_base + (block * cfg->block_size) + off);

    debugf("ROMFS: Read block %ld / ofs %ld [ %ld bytes ] - base addr is %p - target is %p", block, off, size, addr, buffer);

    // TODO check this can handle odd-offsets...
    memcpy(buffer, addr, size);

    debugf(" [DONE]\n");

    return LFS_ERR_OK;
}

int romfs_device_prog(const struct lfs_config *cfg, lfs_block_t block, lfs_off_t off, const void *buffer, lfs_size_t size) {
    debugf("PROG CALLED\n");
    return LFS_ERR_OK;
}

int romfs_device_erase(const struct lfs_config *cfg, lfs_block_t block) {
    debugf("ERASE CALLED\n");
    return LFS_ERR_OK;
}

int romfs_device_sync(const struct lfs_config *fgc) {
    debugf("SYNC CALLED\n");
    return LFS_ERR_OK;
}

static inline void set_lfs_config(void* device_base, ROMFS *fs) {
    memset(fs, 0, sizeof(ROMFS));

    // block device operations
    fs->fs_config.read  = romfs_device_read;
    fs->fs_config.prog = romfs_device_prog;
    fs->fs_config.erase = romfs_device_erase;
    fs->fs_config.sync = romfs_device_sync;

    // block device configuration
    fs->fs_config.read_size = ROMFS_READ_SIZE;
    fs->fs_config.prog_size = ROMFS_PROG_SIZE;
    fs->fs_config.block_size = ROMFS_BLOCKSIZE;
    fs->fs_config.block_count = ROMFS_BLOCKS;
    fs->fs_config.cache_size = ROMFS_CACHE_SIZE;
    fs->fs_config.lookahead_size = ROMFS_LA_SIZE;
    fs->fs_config.block_cycles = LFS_BLOCK_CYCLES;
    fs->fs_config.read_buffer = &fs->read_buffer;
    fs->fs_config.prog_buffer = &fs->prog_buffer;
    fs->fs_config.lookahead_buffer = &fs->lookahead_buffer;

    // fs configuration
    fs->device_base = device_base;
    fs->fs_config.context = fs;

    debugf("LFS config: FS @ %p; BUFFER @ %p\n", (void*)fs, fs->fs_config.read_buffer);
}

static inline void set_lfs_file_config(ROMFS *fs, ROMFS_File *file) {
    memset(file, 0, sizeof(ROMFS_File));

    debugf("LFS file config: FS @ %p; FILE @ %p, BUFFER @ %p\n", (void*)fs, (void*)file, file->cache);

    file->fs = fs;
    file->fs_config.buffer = file->cache;
}

ROMFS_ERR romfs_mount(void *device_base, ROMFS *fs) {
    set_lfs_config(device_base, fs);

    return lfs_mount(&fs->fs_info, &fs->fs_config);
}

ROMFS_ERR romfs_file_open(ROMFS *fs, char *path, ROMFS_OpenFlags flags, ROMFS_File *file) {    
    set_lfs_file_config(fs, file);

    return lfs_file_opencfg(&fs->fs_info, &file->fs_info, path, flags, &file->fs_config);
}

ssize_t romfs_file_size(ROMFS_File *file) {
    return lfs_file_size(&file->fs->fs_info, &file->fs_info);
}

ssize_t romfs_file_read(ROMFS_File *file, void *buffer, size_t size) {
    return lfs_file_read(&file->fs->fs_info, &file->fs_info, buffer, size);
}

ROMFS_ERR romfs_file_close(ROMFS_File *file) {
    return lfs_file_close(&file->fs->fs_info, &file->fs_info);
}

ROMFS_ERR romfs_unmount(ROMFS *fs) {
    return lfs_unmount(&fs->fs_info);
}

ssize_t romfs_file_write(ROMFS_File *file, void *buffer, size_t size) {
    // TODO not yet supported
    return ROMFS_ERR_NOTSUPP;
}

ROMFS_ERR romfs_file_seek(ROMFS_File *file, off_t ofs) {
    // TODO not yet supported
    return ROMFS_ERR_NOTSUPP;
}

long romfs_file_tell(ROMFS_File *file) {
    // TODO not yet supported
    return ROMFS_ERR_NOTSUPP;
}

ROMFS_ERR romfs_file_delete(ROMFS_File *file) {
    // TODO not yet supported
    return ROMFS_ERR_NOTSUPP;
}
