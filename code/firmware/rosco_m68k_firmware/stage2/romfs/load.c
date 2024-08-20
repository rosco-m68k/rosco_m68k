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
#include <sys/types.h>

#include "machine.h"
#include "romfs.h"

#ifdef DEBUG_ROMFS
#include <stdio.h>
#define debugf(...)         printf(__VA_ARGS__)
#else
#define debugf(...)         ((void)(0))
#endif

extern uint8_t *kernel_load_ptr;

static ROMFS_ERR romfs_try_load_internal(char *filename, void *romfs_addr, void *load_buffer, int load_buffer_size, bool boot_romfs) {
    ROMFS fs;
    ROMFS_File file;

    if (filename == NULL || romfs_addr == NULL || load_buffer == NULL) {
        debugf("[BUG]: try_load called with NULL args");
        return ROMFS_ERR_INVAL;
    }

    debugf("ROMFS Init:");
    int err = romfs_mount(romfs_addr, &fs);
    if (err != ROMFS_ERR_OK) {
        debugf("  No mount: %d\n", err);
        return err;
    }

    err = romfs_file_open(&fs, filename, ROMFS_O_RDONLY, &file);
    if (err != ROMFS_ERR_OK) {
        debugf("  No open: %d\n", err);
        return err;
    }
    
    ssize_t size = romfs_file_size(&file);
    if (size < 0) {
        return ROMFS_ERR_CORRUPT;
    }

    if (boot_romfs) {
        FW_PRINT_C("Found bootable ROMFS - loading...\r\n");
    }

    // Yeah, this -1 option is a bit dangerous, but when loading kernels we've always 
    // ignored the load size and just gone until potential bus error. 
    //
    // Should probably compute this as ram top - stack - load position...
    //
    if (load_buffer_size > -1 && size > load_buffer_size) {
        return ROMFS_ERR_NOSPC;
    }

    debugf("Got size, is %ld\n", size);

    ssize_t actual = romfs_file_read(&file, load_buffer, size);
    romfs_file_close(&file);
    romfs_unmount(&fs);

    if (actual != size) {
        debugf(" [read: %ld but expected %ld ] ", actual, size);
        return ROMFS_ERR_CORRUPT;
    }

    return actual;
}

ROMFS_ERR romfs_try_load(char *filename, void *romfs_addr, void *load_buffer, int load_buffer_size) {
    return romfs_try_load_internal(filename, romfs_addr, load_buffer, load_buffer_size, false);
}

bool romfs_load_kernel(void) {
    ROMFS_ERR result = romfs_try_load_internal("/ROSCODE1.BIN", ((void*)ROMFS_BASE), kernel_load_ptr, -1, true);

    if (result == ROMFS_ERR_CORRUPT) {
        FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Bootable ROMFS load failed; ROMFS may be corrupt!\r\n");
    }

    return result > 0;
}

