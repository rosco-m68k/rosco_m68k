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
 * Slab allocator, for system structures.
 * 
 * This allocator manages 1KiB slabs of physical memory, and
 * allocates them out in chunks of 32-bytes.
 * 
 * Since a few system structures are larger than a single
 * chunk, it supports efficient allocation / deallocation
 * of contiguous chunks.
 * 
 * **Note**: The implementation of this is built around pmm
 * managing 1KiB pages - if that should change, this will
 * need some work too!
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_KERNEL_SLAB_H
#define _ROSCOM68K_KERNEL_SLAB_H

#include "list.h"

#define NODE_TYPE_SLAB      0x200

// Find the slab base address from an arbitrary slab address
#define slab_base(addr)     (( (void*)(((uint32_t)addr) & 0xfffffc00) ))

// Get a pointer to the slab metadata given an arbitrary slab address
#define slab_metadata(addr) (( ((Slab*)slab_base(addr)) + 31 ))

typedef volatile struct {
    ListNode            node;
    uint32_t            base_addr;
    uint32_t            bitmap;
    uint32_t            pad[2];
} Slab;

/**
 * Initialise the slab system.
 * 
 * **Must** be called before it is used!
 */
void    slab_init(void);

/**
 * Allocate `block_count` contiguous blocks using the slab allocator.
 * 
 * Will attempt to allocate in a partial block, and will allocate
 * a new block if there isn't one with enough space.
 * 
 * @param block_count number of blocks (max 31)
 * @return void* Pointer to the block, or NULL on failure
 */
void*   slab_alloc_c(uint8_t block_count);

/**
 * Free the `block_count` contiguous blocks pointed to by `addr`.
 * 
 * Will free the blocks, and where this results in slabs becoming
 * empty, they will also have their physical memory freed.
 * 
 * TODO it's probably worth having some option to keep slabs 
 * around (not free their phys mem) until memory pressure demands
 * it, especially for oft-created-and-destroyed structs 🤔
 * 
 * @param addr base address of first block
 * @param block_count number of blocks (max 31)
 * @return void* Pointer to the block, or NULL on failure
 */
void    slab_free_c(void* addr, uint8_t block_count);

#endif//_ROSCOM68K_KERNEL_SLAB_H
