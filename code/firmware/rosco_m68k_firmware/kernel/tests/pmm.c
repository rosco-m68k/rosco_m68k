
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
 * Some ad-hoc tests of the PMM
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdio.h>

#include "pmm.h"

static void print_list(List *list) {
    ListNode *current = (ListNode*)list;
    while (current) {
        if (current->prev == NULL) {
            printf("<head> => ");
        } else if (current->next == NULL) {
            printf("<tail>\n");
        } else {
            printf("[0x%08x]: %d => ", (uint32_t)current, current->size);
        }
        current = current->next;
    }
}

extern List pmm_addr_list;
extern List pmm_size_list;

void do_free_test(uintptr_t addr, uintptr_t size) {
    pmm_free(addr, size);
    print_list(&pmm_addr_list);
    print_list(&pmm_size_list);
    printf("\n-------------------------\n");
}

uintptr_t do_alloc_test(uintptr_t size) {
    uintptr_t result = pmm_alloc(size);
    printf("Allocated %d bytes at 0x%08x\n", size, result);
    print_list(&pmm_addr_list);
    print_list(&pmm_size_list);
    printf("\n-------------------------\n");
    return result;
}

void kmain() {
    pmm_init();
    print_list(&pmm_addr_list);

    // Should just add - first block
    do_free_test(0x1000, 0x100);

    // Should get coalesced with block below
    do_free_test(0x1100, 0x100);

    // Should be added at start of list as a separate block as not contiguous
    do_free_test(0x0e00, 0x100);

    // Should cause all blocks to coalesce as it fills the gap
    do_free_test(0x0f00, 0x100);

    // Should add at beginning of both lists, no coalescing
    do_free_test(0x0a00, 0x80);

    // Should add at end of address list, but beginning of size list
    do_free_test(0x10000, 0x20);

    // Should split 1024-byte block and alloc at 0x0e00
    uintptr_t xe00 = do_alloc_test(0x100);

    // Should split 128-byte block and alloc at 0x0a00
    uintptr_t xa00 = do_alloc_test(0x40);

    // Should just alloc 32-byte block and alloc at 0x10000
    uintptr_t x10000 = do_alloc_test(0x20);

    printf("%d %d %d\n", xe00, xa00, x10000);
    
    printf("It's all over!\n");
}