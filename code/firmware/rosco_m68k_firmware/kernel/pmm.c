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
 * 
 * This is a simple free-list physical memory manager.
 * It looks after 1KiB blocks of physical RAM in a reasonably
 * performant, constant low-overhead fashion.
 * 
 * General space/performance (best/average/worst) profile:
 * 
 *   * Alloc is very fast / not too bad / very slow
 *   * Free is not too bad / slow / very slow
 *   * Space overhead is constant 96 bytes
 * 
 * I chose this because we don't have a lot of RAM and this is 
 * more space-efficient than (e.g.) bitmapped buddy - the only
 * overhead is the two list head pointers, everything else is 
 * stored within the free memory blocks.
 * 
 * It has a few optimizations to support faster alloc/free with
 * coalescing (basically, it manages free memory as two sorted 
 * lists, one by address, and the other by size).
 * 
 * Allocated blocks are not tracked by this subsystem - we'll
 * have to do that in a higher layer (or not at all). This is 
 * intended as a very low-level allocator, so it doesn't track
 * block sizes either - that's on the caller.
 * 
 * (It's worth noting that, because allocated blocks aren't 
 * tracked, initializing the memory blocks at start-up is just
 * done by freeing them - no need for additional init logic...)
 * 
 * The two lists track:
 * 
 *   * The memory blocks, ordered by address (ascending)
 *   * The memory blocks, ordered by size (ascending)
 * 
 * The first list lets us coalesce in a reasonably efficient 
 * manner, while the second lets us do first-fit allocation,
 * again with reasonable probable-average-case efficiency.
 * 
 * The size list has a minor wierdness in the implementation 
 * details - the actual pointers are off by +sizeof(ListNode)
 * (currently 16 bytes) due to the way the lists are implemented.
 * This is totally transparent to callers.
 * 
 * Warnings:
 * 
 *   * Don't use this for small allocations. You can ask it
 *     for < 1KiB, but it will always alloc in blocks of that
 *     size!
 *   * Don't free blocks that aren't on 1KiB boundaries, or 
 *     _bad things_ are likely to happen. It doesn't currently
 *     check this (but maybe should?)
 * 
 * Ideas for investigation / enhancement:
 * 
 *   * Don't use free in alloc when splitting blocks
 *   * Do we want to coalesce on every free?
 *   * Would our use case fit better with a reversed list traversal?
 *     * I don't _think_ so but could do with analysis...
 * 
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#include "kmachine.h"
#include "list.h"
#include "pmm.h"

#ifndef PMM_MIN_SIZE
#   define PMM_MIN_SIZE     0x400     /* TODO Might want to be bigger IRL */
#   define PMM_SIZE_MASK    (~0x3ff)
#endif

#ifdef DEBUG_PMM
#   include <stdio.h>
#   define debugf(...)      printf(__VA_ARGS__)
#else
#   define debugf(...)
#endif

#ifdef UNIT_TESTS
#   define NODEBUG_STATIC
#else
#   define NODEBUG_STATIC   static
#endif

NODEBUG_STATIC List pmm_addr_list;
NODEBUG_STATIC List pmm_size_list;

void pmm_init() {
    list_init_c(&pmm_addr_list);
    list_init_c(&pmm_size_list);
}

void pmm_free(uintptr_t addr, uintptr_t size) {    
    disable_interrupts();

    uintptr_t alloc_size = size & PMM_SIZE_MASK;
    if (alloc_size < size) {
        size = alloc_size + PMM_MIN_SIZE;
    }

    debugf("FREE: %d bytes at 0x%08x\n", size, addr);

    // Set up nodes within the block
    ListNode *this_addr = (ListNode*)addr;
    ListNode *this_size = this_addr + 1;

    this_addr->size = this_size->size = size;

    // Stores the addr_list node we'll add the new one after
    ListNode *previous_node = NULL;

    // Coalesce happens in multiple passes (which will probably be the biggest bottleneck
    // here in the worst case). It just keeps going until it can't coalese any more
    // (detected in the `else if` branch).
    //
    // Also, coalesce is done based on address (obvs). The size list isn't handled until later.
    //
    while (1) {

        // Loop through the list until we find the node with the next-highest address.
        //
        for (ListNode *current = pmm_addr_list.head; current->next; current = current->next) {

            // Is the node immediately above the block we're freeing?
            //
            if (current == ((ListNode*)(addr + size))) {
                // Coalesce with higher
                debugf("Coalesce 0x%08x:%04x and higher 0x%08x:%04x\n", addr, size, (uint32_t)current, current->size);

                // Delete the current node from both lists
                list_node_delete_c(current);
                list_node_delete_c(current + 1);

                // Expand the node we're adding
                this_addr->size = this_size->size = this_addr->size + current->size;

                goto continue_coalesce;     // Yep, it's like that. Deal with it 🤷


            // Maybe it's directly below then?
            //
            } else if (current == ((ListNode*)(addr - current->size))) {
                // Coalesce with lower
                debugf("Coalesce 0x%08x:%04x and lower  0x%08x:%04x\n", addr, size, (uint32_t)current, current->size);

                // Delete the current node from both lists
                list_node_delete_c(current);
                list_node_delete_c(current + 1);

                // Expand the current node
                size += current->size;
                current->size = (current + 1)->size = size;

                // And switch to using that node instead of our original one...
                this_addr = current;
                this_size = current + 1;
                addr = (uint32_t)current;

                goto continue_coalesce;


            // Okay, it's not adjacent then, but at least we're in the right place in
            // the address list to add it, so just go do that (this is the break 
            // condition for the coalesce loop).
            //
            } else if (current > this_addr) {                    
                // Can't coalesce any more, so we're done
                debugf("No (more) coalescing for 0x%08x:%04x\n", addr, size);
                previous_node = current->prev;

                goto add_to_prev;
            }
        }

        // If here, we ran out of entries, i.e. none of the address had an address
        // higher than the one we're freeing.
        //
        // Might be a red flag, but might not. Either way this subsystem doesn't
        // care so we're just gonna add at the end of the list 😎
        //
        debugf("Adding at end of list\n");
        list_add_tail_c(&pmm_addr_list, this_addr);
        goto add_to_size_list;

continue_coalesce:
        continue;       // Not strictly needed, just avoids a warning...
    }

add_to_prev:
    debugf("Adding after previous 0x%08x\n", previous_node);
    list_node_insert_after_c(previous_node, this_addr);

add_to_size_list:
    // This is nice and simple - the loop for address 👆 did most of the hard work,
    // this just needs to find the right place and add.
    //
    for (ListNode *current = pmm_size_list.head; current->next; current = current->next) {
        if (current->size > size) {
            list_node_insert_after_c(current->prev, this_size);
            goto done;
        }
    }

    // If we're here, we ran out of entries - just add at the end
    list_add_tail_c(&pmm_size_list, this_size);

done:
    enable_interrupts();
}

uintptr_t pmm_alloc(uintptr_t size) {
    disable_interrupts();

    debugf("ALLOCATE 0x%08x\n", size);

    uintptr_t alloc_size = size & PMM_SIZE_MASK;
    if (alloc_size < size) {
        size = alloc_size + PMM_MIN_SIZE;
    }

    for (ListNode *current = pmm_size_list.head; current->next; current = current->next) {
        debugf("Check block at 0x%08x [size 0x%08x]\n", current, current->size);
        if (current->size > size) {
            // split block - delete the current node from both lists (TODO inefficient!)
            debugf("Will split this block\n");

            list_node_delete_c(current);
            list_node_delete_c(current - 1);

            // Free the remaining block to keep the lists ordered
            // TODO there has to be a better way to do this!
            //
            // This is the only reason for the "not great" performance profile of alloc,
            // if not for this it would be constant time 🙄
            pmm_free(((uintptr_t)(current - 1)) + size, current->size - size);

            enable_interrupts();
            return ((uintptr_t)current) - sizeof(ListNode);
        } else if (current->size == size) {
            // just delete the current node from both lists and return it
            debugf("Will allocate this block\n");

            list_node_delete_c(current);
            list_node_delete_c(current - 1);

            enable_interrupts();
            return ((uintptr_t)current) - sizeof(ListNode);
        }
    }

    // If here, out of memory (or too fragmented)
    enable_interrupts();
    return 0;
}

