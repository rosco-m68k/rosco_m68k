
/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|            kernel
 * ------------------------------------------------------------
 * Copyright (c)2023 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Physical memory manager.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_KERNEL_PMM_H
#define _ROSCOM68K_KERNEL_PMM_H

#include "list.h"

typedef struct {
    ListNode*       addr;
    ListNode*       size;
} FreeBlockHeader;

/**
 * Initialise the PMM.
 * 
 * **Must** be called before it is used!
 */
void pmm_init();

/**
 * Free a block of the given size, at the given
 * address.
 * 
 * @param addr Base address for the new block
 * @param size Block size, in bytes (min 256).
 */
void pmm_free(uintptr_t addr, uintptr_t size);

/**
 * Allocate a block of the given size.
 * 
 * @param size Block size, in bytes (min 256)
 * @return uintptr_t The allocated block, or NULL
 */
uintptr_t pmm_alloc(uintptr_t size);

#endif//_ROSCOM68K_KERNEL_PMM_H
