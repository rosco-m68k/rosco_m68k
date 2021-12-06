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

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include "heap.h"

#define DEFAULT_STACK_SIZE  ((32 << 10)) // Default to 32KB stack

// PLATFORM_THRESHOLD determines the minimum number of bytes needed to not use
// the platform-independant naive implementation
#if __m68k__
#define PLATFORM_THRESHOLD 16
// Data unit used by fast loop
typedef uint32_t chunk_type;    // The type of each data unit, matches CHUNK_LETTER
#define CHUNK_LETTER "l"        // The m68k instruction suffix, matches chunk_type
#else
#define PLATFORM_THRESHOLD 0
#endif

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

void* malloc(size_t size) {
    return heap_alloc(current_heap, size);
}

void free(void* ptr) {
    if (ptr) {
        heap_free(current_heap, ptr);
    }
}

static void mem_clear(void *dst, size_t count) {
    uint8_t *bdst = (uint8_t *) dst;
    size_t count_left = count;

    // Don't bother going fast with overhead for small sets
    if (count_left < PLATFORM_THRESHOLD) {
        goto platform_done;
    }

    // Handle the platform-specific case
#if __m68k__
    // Handle misaligned pointer bytes
    while ((uintptr_t) bdst % alignof(chunk_type)) {
        *(bdst++) = 0;
        count_left -= 1;
    }

    // Loop over fast loop, fast loop limited to 16-bit counts
    while (count_left >= sizeof(chunk_type)) {
        // Calculate the number of fast loop iterations (minus one)
        size_t chunks_left = count_left / sizeof(chunk_type);
        uint16_t loop_counter = (uint16_t) (chunks_left - 1);
        size_t chunks_to_loop = (size_t) loop_counter + 1;
        count_left -= chunks_to_loop * sizeof(chunk_type);

        // Fast loop, uses MC68010 loop mode
        __asm__ volatile (
            "1: clr" CHUNK_LETTER " %[bdst]@+\n\t"
            "dbf %[loop_counter], 1b"
            : [bdst] "+a" (bdst),
              [loop_counter] "+d" (loop_counter)
            :
            : "cc", "memory"
        );
    }
#endif

platform_done:
    // Handle any bytes left
    for (; count_left > 0; --count_left) {
        *(bdst++) = 0;
    }
}

// Pointers must point to non-overlapping data
static void mem_copy(void *dst, const void *src, size_t count) {
    uint8_t *bdst = (uint8_t *) dst;
    uint8_t *bsrc = (uint8_t *) src;
    size_t count_left = count;

    // Don't bother going fast with overhead for small sets
    if (count_left < PLATFORM_THRESHOLD) {
        goto platform_done;
    }

    // Handle the platform-specific case
#if __m68k__
    // If the destination and source have different chunk alignment offsets,
    // the fast code can't be used
    if ((uintptr_t) bdst % alignof(chunk_type) != (uintptr_t) bsrc % alignof(chunk_type)) {
        goto platform_done;
    }

    // Handle misaligned pointer bytes
    while ((uintptr_t) bdst % alignof(chunk_type) || (uintptr_t) bsrc % alignof(chunk_type)) {
        *(bdst++) = *(bsrc++);
        count_left -= 1;
    }

    // Loop over fast loop, fast loop limited to 16-bit counts
    while (count_left >= sizeof(chunk_type)) {
        // Calculate the number of fast loop iterations (minus one)
        size_t chunks_left = count_left / sizeof(chunk_type);
        uint16_t loop_counter = (uint16_t) (chunks_left - 1);
        size_t chunks_to_loop = (size_t) loop_counter + 1;
        count_left -= chunks_to_loop * sizeof(chunk_type);

        // Fast loop, uses MC68010 loop mode
        __asm__ volatile (
            "1: move" CHUNK_LETTER " %[bsrc]@+, %[bdst]@+\n\t"
            "dbf %[loop_counter], 1b"
            : [bdst] "+a" (bdst),
              [bsrc] "+a" (bsrc),
              [loop_counter] "+d" (loop_counter)
            :
            : "cc", "memory"
        );
    }
#endif

platform_done:
    // Handle any bytes left
    for (; count_left > 0; --count_left) {
        *(bdst++) = *(bsrc++);
    }
}

void* calloc(size_t num, size_t size) {
    size_t total = num * size;
    void *mem = malloc(total);

    if (mem != NULL && total > 0) {
        mem_clear(mem, total);
    }

    return mem;
}

void* realloc(void *ptr, size_t new_size) {
    void *new_ptr = malloc(new_size);

    if (ptr != NULL && new_ptr != NULL && new_size > 0) {
        node_t *old_node = get_head(ptr);
        size_t old_size = old_node->size;
        size_t copy_size = old_size < new_size ? old_size : new_size;
        mem_copy(new_ptr, ptr, copy_size);
        free(ptr);
    }

    return new_ptr;
}

#ifdef __cplusplus
}

// Argument types of std::size_t are replaced with size_t
// Overloads that use std::align_val_t or std::nothrow_t are not included.

void* operator new  (size_t count)  { return ::malloc(count); }
void* operator new[](size_t count)  { return operator new  (count); }

void operator delete  (void* ptr) noexcept          { ::free(ptr); }
void operator delete[](void* ptr) noexcept          { operator delete  (ptr); }
void operator delete  (void* ptr, size_t) noexcept  { operator delete  (ptr); }
void operator delete[](void* ptr, size_t) noexcept  { operator delete[](ptr); }

#endif
