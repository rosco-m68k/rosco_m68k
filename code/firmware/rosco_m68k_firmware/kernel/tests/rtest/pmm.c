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
 * Unit tests: pmm allocator
 * ------------------------------------------------------------
 */

#include <stdint.h>

#include "roscotest.h"
#include "list.h"
#include "pmm.h"

extern List pmm_addr_list;
extern List pmm_size_list;

static int test_free_first_block() {
    // Should just add - first block
    pmm_free(0x40000, 0x100);

    // First block is at 0x1000
    assert_that((uint32_t)pmm_addr_list.head == 0x40000);

    // It's at the start of the size list too
    assert_that((uint32_t)pmm_size_list.head == 0x40010);

    // Size is 0x400 - rounded up to minimum block size!
    assert_that((uint32_t)pmm_addr_list.head->size == 0x400);
    assert_that((uint32_t)pmm_size_list.head->size == 0x400);

    // It's the last block
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);
    assert_that((ListNode*)pmm_size_list.head->next == (ListNode*)&pmm_size_list.tail);

    return RTEST_PASS;
}

static int test_free_second_block_coalesce() {
    // Should just add - first block
    pmm_free(0x40000, 0x400);

    // Should get coalesced with block below
    pmm_free(0x40400, 0x400);

    // First block is at 0x40000
    assert_that((uint32_t)pmm_addr_list.head == 0x40000);

    // It's at the start of the size list too
    assert_that((uint32_t)pmm_size_list.head == 0x40010);

    // Size is 0x200
    assert_that((uint32_t)pmm_addr_list.head->size == 0x800);
    assert_that((uint32_t)pmm_size_list.head->size == 0x800);

    // It's the last block
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);
    assert_that((ListNode*)pmm_size_list.head->next == (ListNode*)&pmm_size_list.tail);

    return RTEST_PASS;
}

static int test_free_third_block_non_contig() {
    // Should just add - first block
    pmm_free(0x40000, 0x400);

    // Should get coalesced with block below
    pmm_free(0x40400, 0x400);

    // Should be added at start of list as a separate block as not contiguous
    pmm_free(0x3f800, 0x400);

    // First block is at 0x800
    assert_that((uint32_t)pmm_addr_list.head == 0x3f800);

    // It's at the start of the size list too
    assert_that((uint32_t)pmm_size_list.head == 0x3f810);

    // Size is 0x400
    assert_that((uint32_t)pmm_addr_list.head->size == 0x400);
    assert_that((uint32_t)pmm_size_list.head->size == 0x400);

    // Next block is at 0x1000
    assert_that((uint32_t)pmm_addr_list.head->next == 0x40000);

    // It's next in the size list too
    assert_that((uint32_t)pmm_size_list.head->next == 0x40010);

    // Size is 0x800
    assert_that((uint32_t)pmm_addr_list.head->next->size == 0x800);
    assert_that((uint32_t)pmm_size_list.head->next->size == 0x800);

    // It's the last block
    assert_that((ListNode*)pmm_addr_list.head->next->next == (ListNode*)&pmm_addr_list.tail);
    assert_that((ListNode*)pmm_size_list.head->next->next == (ListNode*)&pmm_size_list.tail);

    return RTEST_PASS;
}

static int test_free_coalesce_gap_filled() {
    // Should just add - first block
    pmm_free(0x40000, 0x400);

    // Should get coalesced with block below
    pmm_free(0x40400, 0x400);

    // Should be added at start of list as a separate block as not contiguous
    pmm_free(0x3f800, 0x400);

    // Should cause all blocks to coalesce as it fills the gap
    pmm_free(0x3fc00, 0x400);

    // Now we're back to one block - at 0x800
    assert_that((uint32_t)pmm_addr_list.head == 0x3f800);

    // It's at the start of the size list too
    assert_that((uint32_t)pmm_size_list.head == 0x3f810);

    // Size is 0x1000
    assert_that((uint32_t)pmm_addr_list.head->size == 0x1000);
    assert_that((uint32_t)pmm_size_list.head->size == 0x1000);

    // It's the last block
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);
    assert_that((ListNode*)pmm_size_list.head->next == (ListNode*)&pmm_size_list.tail);

    return RTEST_PASS;
}

static int test_free_small_block_below() {
    // Should just add - first block
    pmm_free(0x41400, 0x800);

    // Should get coalesced with block below
    pmm_free(0x41C00, 0x800);

    // Should be added at start of list as a separate block as not contiguous
    pmm_free(0x40c00, 0x400);

    // Should cause all blocks to coalesce as it fills the gap
    pmm_free(0x41000, 0x400);

    // Should add at beginning of both lists, no coalescing
    pmm_free(0x40400, 0x400);

    // First block is at 0x400
    assert_that((uint32_t)pmm_addr_list.head == 0x40400);

    // It's at the start of the size list too
    assert_that((uint32_t)pmm_size_list.head == 0x40410);

    // Size is 0x400
    assert_that((uint32_t)pmm_addr_list.head->size == 0x400);
    assert_that((uint32_t)pmm_size_list.head->size == 0x400);

    // Next block is at 0xc00
    assert_that((uint32_t)pmm_addr_list.head->next == 0x40c00);

    // It's next in the size list too
    assert_that((uint32_t)pmm_size_list.head->next == 0x40c10);

    // Size is 0x1800
    assert_that((uint32_t)pmm_addr_list.head->next->size == 0x1800);
    assert_that((uint32_t)pmm_size_list.head->next->size == 0x1800);

    // It's the last block
    assert_that((ListNode*)pmm_addr_list.head->next->next == (ListNode*)&pmm_addr_list.tail);
    assert_that((ListNode*)pmm_size_list.head->next->next == (ListNode*)&pmm_size_list.tail);

    return RTEST_PASS;
}

static int test_free_small_block_after() {
    // Should cause all blocks to coalesce as it fills the gap
    pmm_free(0x40000, 0xc00);

    // Should add at beginning of both lists, no coalescing
    pmm_free(0x3f400, 0x800);

    // Should add at end of address list, but beginning of size list
    pmm_free(0x50000, 0x400);

    // First block is at 0x400
    assert_that((uint32_t)pmm_addr_list.head == 0x3f400);

    // But start of size list is the last block we just added
    assert_that((uint32_t)pmm_size_list.head == 0x50010);

    // Size is 0x800 at beginning of address list
    assert_that((uint32_t)pmm_addr_list.head->size == 0x800);

    // and 0x400 at beginning of size list
    assert_that((uint32_t)pmm_size_list.head->size == 0x400);

    // Next block in address list is at 0x40000 (0xc00 byte block)
    assert_that((uint32_t)pmm_addr_list.head->next == 0x40000);

    // But in size list, it's the 0x400 block at 0x400
    assert_that((uint32_t)pmm_size_list.head->next == 0x3f410);

    // Size is 0xc00 in the address list
    assert_that((uint32_t)pmm_addr_list.head->next->size == 0xc00);

    // But 0x800 in size list
    assert_that((uint32_t)pmm_size_list.head->next->size == 0x800);

    // Next block in address list is at 0x50000 (0x400 byte block)
    assert_that((uint32_t)pmm_addr_list.head->next->next == 0x50000);

    // But in size list, it's the 0x400 block at 0x1000
    assert_that((uint32_t)pmm_size_list.head->next->next == 0x40010);

    // Size is 0x400 in the address list
    assert_that((uint32_t)pmm_addr_list.head->next->next->size == 0x400);

    // But 0xc00 in size list
    assert_that((uint32_t)pmm_size_list.head->next->next->size == 0xc00);

    // It's the last block
    assert_that((ListNode*)pmm_addr_list.head->next->next->next == (ListNode*)&pmm_addr_list.tail);
    assert_that((ListNode*)pmm_size_list.head->next->next->next == (ListNode*)&pmm_size_list.tail);

    return RTEST_PASS;
}

static int test_alloc_split_large_block() {
    // Second block in address list is at 0x42000 (0xc00 byte block)
    assert_that((uint32_t)pmm_addr_list.head->next == 0x42000);
    assert_that((uint32_t)pmm_addr_list.head->next->size == 0x2000);

    // It's the third block in size list
    assert_that((uint32_t)pmm_size_list.head->next->next == 0x42010);
    assert_that((uint32_t)pmm_size_list.head->next->next->size == 0x2000);

    // Should split 3072-byte block and alloc at 0x42000
    uintptr_t x2000 = pmm_alloc(0xc00);
    assert_that(x2000 == 0x42000);

    // Second block in address list is now at 0x42c00 (0x400 byte block)
    assert_that((uint32_t)pmm_addr_list.head->next == 0x42c00);
    assert_that((uint32_t)pmm_addr_list.head->next->size == 0x1400);

    // Still the third block in size list
    assert_that((uint32_t)pmm_size_list.head->next->next == 0x42c10);
    assert_that((uint32_t)pmm_size_list.head->next->next->size == 0x1400);

    return RTEST_PASS;
}

static int test_alloc_whole_block() {
    // Third block in address list is at 0x50000 (0x400 byte block)
    assert_that((uint32_t)pmm_addr_list.head->next->next == 0x50000);
    assert_that((uint32_t)pmm_addr_list.head->next->next->size == 0x400);

    // It's the first block in size list
    assert_that((uint32_t)pmm_size_list.head == 0x50010);
    assert_that((uint32_t)pmm_size_list.head->size == 0x400);

    // Should just alloc 1024-byte block and alloc at 0x50000
    uintptr_t x10000 = pmm_alloc(0x400);
    assert_that(x10000 == 0x50000);

    // Third block in address is now the tail (i.e. block is gone)
    assert_that((ListNode*)pmm_addr_list.head->next->next == (ListNode*)&pmm_addr_list.tail);

    // First block in the size list is now 0x800 byte block at 0x1000
    assert_that((uint32_t)pmm_size_list.head == 0x40010);
    assert_that((uint32_t)pmm_size_list.head->size == 0x800);

    return RTEST_PASS;
}

static int test_alloc_split_large_and_move() {
    // Second block in address list is at 0x42000 (0x42000 byte block)
    assert_that((uint32_t)pmm_addr_list.head->next == 0x42000);
    assert_that((uint32_t)pmm_addr_list.head->next->size == 0x2000);

    // It's the third block in size list
    assert_that((uint32_t)pmm_size_list.head->next->next == 0x42010);
    assert_that((uint32_t)pmm_size_list.head->next->next->size == 0x2000);

    // Should split 8192-byte block and alloc at 0x02000
    uintptr_t xe00 = pmm_alloc(0x1800);
    assert_that(xe00 == 0x42000);

    // Second block in address list is now at 0x3800 (0x800 byte block)
    assert_that((uint32_t)pmm_addr_list.head->next == 0x43800);
    assert_that((uint32_t)pmm_addr_list.head->next->size == 0x800);

    // Now the second block in size list
    assert_that((uint32_t)pmm_size_list.head->next == 0x40010);
    assert_that((uint32_t)pmm_size_list.head->next->size == 0x800);

    return RTEST_PASS;
}

static int test_alloc_multiple() {
    // pre-alloc the 0x800 byte block to remove it from the test...    
    pmm_alloc(0x800);

    // First block in address list is at 0x42000 (0x2000 byte block)
    assert_that((uint32_t)pmm_addr_list.head == 0x42000);
    assert_that((uint32_t)pmm_addr_list.head->size == 0x2000);

    // It's the second block in size list
    assert_that((uint32_t)pmm_size_list.head->next == 0x42010);
    assert_that((uint32_t)pmm_size_list.head->next->size == 0x2000);

    // Should split 4096-byte block and alloc at 0x42000
    uintptr_t x2000 = pmm_alloc(0x1000);
    assert_that(x2000 == 0x42000);

    // First block in address list is now at 0x3000 (0x1000 byte block)
    assert_that((uint32_t)pmm_addr_list.head == 0x43000);
    assert_that((uint32_t)pmm_addr_list.head->size == 0x1000);

    // Still the second block in size list
    assert_that((uint32_t)pmm_size_list.head->next == 0x43010);
    assert_that((uint32_t)pmm_size_list.head->next->size == 0x1000);

    // Should split 1024-byte block and alloc at 0x0e00
    uintptr_t x43000 = pmm_alloc(0x800);
    assert_that(x43000 == 0x43000);

    // First block in address list is now at 0x3800 (0x800 byte block)
    assert_that((uint32_t)pmm_addr_list.head == 0x43800);
    assert_that((uint32_t)pmm_addr_list.head->size == 0x800);

    // It's the second block in size list
    assert_that((uint32_t)pmm_size_list.head->next == 0x43810);
    assert_that((uint32_t)pmm_size_list.head->next->size == 0x800);

    return RTEST_PASS;
}

// TODO test rounding to min alloc size (0x20)

void setup() {
    pmm_init();
}

void setup_alloc() {
    pmm_init();

    // Just set up three blocks for the tests:
    //
    //    0x40000   - 0x800 bytes
    //    0x42000   - 0x2000 bytes
    //    0x50000   - 0x400 bytes
    //
    pmm_free(0x40000, 0x800);
    pmm_free(0x42000, 0x2000);
    pmm_free(0x50000, 0x40);
}

static RTest tests[] = {
    { "/pmm/free_first_block",              test_free_first_block,              setup, NULL },
    { "/pmm/free_second_block_coalesce",    test_free_second_block_coalesce,    setup, NULL },
    { "/pmm/free_third_block_non_contig",   test_free_third_block_non_contig,   setup, NULL },
    { "/pmm/free_coalesce_filled_gap",      test_free_coalesce_gap_filled,      setup, NULL },
    { "/pmm/free_small_block_below",        test_free_small_block_below,        setup, NULL },
    { "/pmm/free_small_block_after",        test_free_small_block_after,        setup, NULL },

    { "/pmm/alloc_split_large_block",       test_alloc_split_large_block,       setup_alloc, NULL },
    { "/pmm/alloc_whole_block",             test_alloc_whole_block,             setup_alloc, NULL },
    { "/pmm/alloc_split_and_move",          test_alloc_split_large_and_move,    setup_alloc, NULL },
    { "/pmm/alloc_multiple",                test_alloc_multiple,                setup_alloc, NULL },
    { NULL, NULL, NULL, NULL },
};

void pmm_suite(void) {
    rtest_main(tests);
}
