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
 * 
 * TODO this should move to librosco (in toolchain) once complete
 * 
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_ROMFS_H
#define __ROSCO_M68K_ROMFS_H

#include <stdint.h>
#include <stddef.h>
#include <sys/types.h>

#include "lfs.h"

#ifndef ROMFS_BLOCKSIZE
#define ROMFS_BLOCKSIZE     ((512))
#endif
#ifndef ROMFS_BLOCKS
#define ROMFS_BLOCKS        ((720))
#endif
#ifndef ROMFS_CACHE_SIZE
#define ROMFS_CACHE_SIZE    ((ROMFS_BLOCKSIZE * 2))
#endif
#ifndef ROMFS_READ_SIZE
#define ROMFS_READ_SIZE     ((ROMFS_BLOCKSIZE * 2))
#endif
#ifndef ROMFS_PROG_SIZE
#define ROMFS_PROG_SIZE     ((ROMFS_BLOCKSIZE))
#endif
#ifndef ROMFS_LA_SIZE
#define ROMFS_LA_SIZE       ((ROMFS_BLOCKSIZE * 2))
#endif

typedef struct {
    void*                   device_base;

    uint8_t                 prog_buffer[ROMFS_PROG_SIZE];
    uint8_t                 read_buffer[ROMFS_READ_SIZE];
    uint8_t                 lookahead_buffer[ROMFS_LA_SIZE];

    lfs_t                   fs_info;
    struct lfs_config       fs_config;
} ROMFS;

typedef struct {
    ROMFS                   *fs;

    uint8_t                 cache[ROMFS_CACHE_SIZE];

    lfs_file_t              fs_info;
    struct lfs_file_config  fs_config;
} ROMFS_File;

typedef enum {
    ROMFS_ERR_OK            = 0,    // No error
    ROMFS_ERR_IO            = -5,   // Error during device operation
    ROMFS_ERR_CORRUPT       = -84,  // Corrupted
    ROMFS_ERR_NOENT         = -2,   // No directory entry
    ROMFS_ERR_EXIST         = -17,  // Entry already exists
    ROMFS_ERR_NOTDIR        = -20,  // Entry is not a dir
    ROMFS_ERR_ISDIR         = -21,  // Entry is a dir
    ROMFS_ERR_NOTEMPTY      = -39,  // Dir is not empty
    ROMFS_ERR_BADF          = -9,   // Bad file number
    ROMFS_ERR_FBIG          = -27,  // File too large
    ROMFS_ERR_INVAL         = -22,  // Invalid parameter
    ROMFS_ERR_NOSPC         = -28,  // No space left on device
    ROMFS_ERR_NOMEM         = -12,  // No more memory available
    ROMFS_ERR_NOATTR        = -61,  // No data/attr available
    ROMFS_ERR_NAMETOOLONG   = -36,  // File name too long
    ROMFS_ERR_NOTSUPP       = -127  // Operation not supported
} ROMFS_ERR;

typedef enum  {
    ROMFS_O_RDONLY          = 1,         // Open a file as read only
    ROMFS_O_WRONLY          = 2,         // Open a file as write only
    ROMFS_O_RDWR            = 3,         // Open a file as read and write
    ROMFS_O_CREAT           = 0x0100,    // Create a file if it does not exist
    ROMFS_O_EXCL            = 0x0200,    // Fail if a file already exists
    ROMFS_O_TRUNC           = 0x0400,    // Truncate the existing file to zero size
    ROMFS_O_APPEND          = 0x0800,    // Move to end of file on every write
} ROMFS_OpenFlags;

ROMFS_ERR romfs_mount(void *device_base, ROMFS *fs);
ROMFS_ERR romfs_file_open(ROMFS *fs, char *path, ROMFS_OpenFlags flags, ROMFS_File *file);
ssize_t romfs_file_size(ROMFS_File *file);
ssize_t romfs_file_read(ROMFS_File *file, void *buffer, size_t size);
ROMFS_ERR romfs_file_close(ROMFS_File *file);
ssize_t romfs_file_write(ROMFS_File *file, void *buffer, size_t size);
ROMFS_ERR romfs_file_seek(ROMFS_File *file, off_t ofs);
long romfs_file_tell(ROMFS_File *file);
ROMFS_ERR romfs_file_delete(ROMFS_File *file);
ROMFS_ERR romfs_unmount(ROMFS *fs);

#endif