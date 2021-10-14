/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|          firmware
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * rosco_m68k interface to shmall heap allocator
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <stdint.h>
#include "heap.h"

#define DEFAULT_STACK_SIZE  ((32 << 10)) // Default to 32KB stack

extern uint32_t _SDB_MEM_SIZE;
extern uint32_t _end;

static bin_t bins[BIN_COUNT];
static heap_t __ROSCO_DEFAULT_HEAP;
static heap_t *current_heap;

static void init_malloc_with_stacksize(uint32_t stacksize) {
    uint32_t heapstart = ((uint32_t)&_end);
    uint32_t heapsize = _SDB_MEM_SIZE - stacksize - heapstart;

    for (int i = 0; i < BIN_COUNT; i++) {
        bins[i].head = 0;
        __ROSCO_DEFAULT_HEAP.bins[i] = &bins[i];
    }

    init_heap(&__ROSCO_DEFAULT_HEAP, heapstart, heapsize);
}

__attribute__((constructor)) void __init_default_heap() {
    init_malloc_with_stacksize(DEFAULT_STACK_SIZE);
    current_heap = &__ROSCO_DEFAULT_HEAP;
}


void rh_switch_heap(heap_t *heap) {
    current_heap = heap;
}

void rh_default_heap() {
    current_heap = &__ROSCO_DEFAULT_HEAP;
}

void* malloc(uint32_t size) {
    return heap_alloc(current_heap, size);
}

void free(void* ptr) {
    heap_free(current_heap, ptr);
}

