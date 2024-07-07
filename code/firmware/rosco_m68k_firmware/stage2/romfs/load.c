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

// TODO this is hardcoded to 360KB, needs to support 1440 (for 720KB) too...
//
// Should be linker-provided really...
#ifndef ROMFS_BASE
#define ROMFS_BASE          (((void*)(0x00E26000)))
#endif

#ifdef DEBUG_ROMFS
#include <stdio.h>
#define debugf(...)         printf(__VA_ARGS__)
#else
#define debugf(...)         ((void)(0))
#endif

extern uint8_t *kernel_load_ptr;

static bool try_boot(void *addr) {
    ROMFS fs;
    ROMFS_File file;

    debugf("ROMFS Init:");
    int err = romfs_mount(ROMFS_BASE, &fs);
    if (err != ROMFS_ERR_OK) {
        debugf("  No mount: %d\n", err);
        return false;
    }

    err = romfs_file_open(&fs, "/ROSCODE1.BIN", ROMFS_O_RDONLY, &file);
    if (err != ROMFS_ERR_OK) {
        debugf("  No open: %d\n", err);
        return false;
    }
    
    FW_PRINT_C("Found bootable ROMFS");

    ssize_t size = romfs_file_size(&file);
    if (size < 0) {
        FW_PRINT_C(", but failed to read, skipping it.\r\n");
        return false;
    }

    debugf("Got size, is %ld\n", size);
    FW_PRINT_C(" - booting it.\r\n");

    ssize_t actual = romfs_file_read(&file, kernel_load_ptr, size);
    romfs_file_close(&file);
    romfs_unmount(&fs);

    if (actual != size) {
        debugf(" [read: %ld but expected %ld ] ", actual, size);
        FW_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Bootable ROMFS load failed; ROMFS may be corrupt!\r\n");
        return false;
    }

    return true;
}

bool romfs_load_kernel(void) {
    return try_boot((void*)ROMFS_BASE);
}

