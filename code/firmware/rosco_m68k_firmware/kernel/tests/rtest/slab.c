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
 * Unit tests: slab allocator
 * 
 * TODO these tests are kinda coupled to the pmm implementation,
 * e.g. if we stop allocating first-fit these are gonna break. 
 * ------------------------------------------------------------
 */

#include <stdint.h>

#include "roscotest.h"
#include "list.h"
#include "pmm.h"
#include "slab.h"

extern volatile List partial_slabs;
extern volatile List full_slabs;
extern volatile List pmm_addr_list;

static int test_alloc_zero() {
    void *result = slab_alloc_c(0);

    assert_that(result == NULL);

    return RTEST_PASS;
}

static int test_alloc_over_31() {
    void *result = slab_alloc_c(32);

    assert_that(result == NULL);

    result = slab_alloc_c(132);

    assert_that(result == NULL);

    return RTEST_PASS;
}

static int test_alloc_one_new_slab() {
    ////////////////////
    // NO MEMORY IS ALLOCATED - JUST ONE BLOCK EXISTS AT 0x50000
    assert_that((uint32_t)pmm_addr_list.head == 0x50000);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // NO SLABS ARE ALLOCATED
    assert_that(partial_slabs.head == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    void *result = slab_alloc_c(1);

    ////////////////////
    // SLAB ALLOCATED AT BOTTOM OF MEMORY
    assert_that(result == (void*)0x50000);
 
    ////////////////////
    // ONE KiB IS ALLOCATED - JUST ONE BLOCK EXISTS, NOW AT 0x50400
    assert_that((uint32_t)pmm_addr_list.head == 0x50400);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // ALLOCATED = ONE PARTIAL SLAB, NO FULL SLABS
    assert_that(partial_slabs.head->next == (ListNode*)&partial_slabs.tail);    
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    ////////////////////
    // ALLOCATED SLAB METADATA IS CORRECT
    Slab* meta = slab_metadata(result);

    assert_that(meta->node.size == 0x400);
    assert_that(meta->node.type == NODE_TYPE_SLAB);
    assert_that(meta->base_addr == 0x50000);
    assert_that(meta->bitmap == 0x80000001);

    return RTEST_PASS;
}

static int test_alloc_two_blocks() {
    ////////////////////
    // NO MEMORY IS ALLOCATED - JUST ONE BLOCK EXISTS AT 0x50000
    assert_that((uint32_t)pmm_addr_list.head == 0x50000);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // NO SLABS ARE ALLOCATED
    assert_that(partial_slabs.head == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    void *result = slab_alloc_c(2);

    ////////////////////
    // SLAB ALLOCATED AT BOTTOM OF MEMORY
    assert_that(result == (void*)0x50000);
 
    ////////////////////
    // ONE KiB IS ALLOCATED - JUST ONE BLOCK EXISTS, NOW AT 0x50400
    assert_that((uint32_t)pmm_addr_list.head == 0x50400);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // ALLOCATED = ONE PARTIAL SLAB, NO FULL SLABS
    assert_that(partial_slabs.head->next == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    ////////////////////
    // ALLOCATED SLAB METADATA IS CORRECT
    Slab* meta = slab_metadata(result);

    assert_that(meta->node.size == 0x400);
    assert_that(meta->node.type == NODE_TYPE_SLAB);
    assert_that(meta->base_addr == 0x50000);
    assert_that(meta->bitmap == 0x80000003);

    return RTEST_PASS;
}

static int test_alloc_31_blocks() {
    ////////////////////
    // NO MEMORY IS ALLOCATED - JUST ONE BLOCK EXISTS AT 0x50000
    assert_that((uint32_t)pmm_addr_list.head == 0x50000);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // NO SLABS ARE ALLOCATED
    assert_that(partial_slabs.head == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    void *result = slab_alloc_c(31);

    ////////////////////
    // SLAB ALLOCATED AT BOTTOM OF MEMORY
    assert_that(result == (void*)0x50000);
 
    ////////////////////
    // ONE KiB IS ALLOCATED - JUST ONE BLOCK EXISTS, NOW AT 0x50400
    assert_that((uint32_t)pmm_addr_list.head == 0x50400);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // ALLOCATED = NO PARTIAL SLABS, ONE FULL SLAB
    assert_that(partial_slabs.head == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head->next == (ListNode*)&full_slabs.tail);

    ////////////////////
    // ALLOCATED SLAB METADATA IS CORRECT
    Slab* meta = slab_metadata(result);

    assert_that(meta->node.size == 0x400);
    assert_that(meta->node.type == NODE_TYPE_SLAB);
    assert_that(meta->base_addr == 0x50000);
    assert_that(meta->bitmap == 0xffffffff);

    return RTEST_PASS;
}

static int test_alloc_two_blocks_separately() {
    ////////////////////
    // NO MEMORY IS ALLOCATED - JUST ONE BLOCK EXISTS AT 0x50000
    assert_that((uint32_t)pmm_addr_list.head == 0x50000);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    // Alloc one full slab 
    void *result1 = slab_alloc_c(1);

    // Allocate a second slab
    void *result2 = slab_alloc_c(2);

    ////////////////////
    // SLABS ALLOCATED AT BOTTOM OF MEMORY
    assert_that(result1 == (void*)0x50000);
    assert_that(result2 == (void*)0x50020);
 
    ////////////////////
    // ONE KiB IS ALLOCATED - JUST ONE BLOCK EXISTS, NOW AT 0x50400
    assert_that((uint32_t)pmm_addr_list.head == 0x50400);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // ALLOCATED = ONE PARTIAL SLAB, NO FULL SLABS
    assert_that(partial_slabs.head->next == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    ////////////////////
    // ALLOCATED SLAB METADATA IS CORRECT
    Slab* meta = slab_metadata(result1);

    assert_that(meta->node.size == 0x400);
    assert_that(meta->node.type == NODE_TYPE_SLAB);
    assert_that(meta->base_addr == 0x50000);
    assert_that(meta->bitmap == 0x80000007);

    return RTEST_PASS;
}

static int test_alloc_two_slabs() {
    ////////////////////
    // NO MEMORY IS ALLOCATED - JUST ONE BLOCK EXISTS AT 0x50000
    // TODO figure out why commenting these out makes the assertion on these lists later fail 🤔
    assert_that((uint32_t)pmm_addr_list.head == 0x50000);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    // Alloc one full slab 
    void *result1 = slab_alloc_c(31);

    // Allocate a second slab
    void *result2 = slab_alloc_c(1);

    ////////////////////
    // SLABS ALLOCATED AT BOTTOM OF MEMORY
    // First in in slab 1
    assert_that(result1 == (void*)0x50000);

    // Second in slab 2
    assert_that(result2 == (void*)0x50400);
 
    ////////////////////
    // ONE KiB IS ALLOCATED - JUST ONE BLOCK EXISTS, NOW AT 0x50800
    assert_that((uint32_t)pmm_addr_list.head == 0x50800);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // ALLOCATED = ONE PARTIAL SLAB, ONE FULL SLAB
    assert_that(partial_slabs.head->next == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head->next == (ListNode*)&full_slabs.tail);

    ////////////////////
    // ALLOCATED SLAB METADATA IS CORRECT
    Slab* meta = slab_metadata(result1);

    assert_that(meta->node.size == 0x400);
    assert_that(meta->node.type == NODE_TYPE_SLAB);
    assert_that(meta->base_addr == 0x50000);
    assert_that(meta->bitmap == 0xffffffff);

    meta = slab_metadata(result2);

    assert_that(meta->node.size == 0x400);
    assert_that(meta->node.type == NODE_TYPE_SLAB);
    assert_that(meta->base_addr == 0x50400);
    assert_that(meta->bitmap == 0x80000001);

    return RTEST_PASS;
}

static int test_free_one_new_slab() {
    ////////////////////
    // NO MEMORY IS ALLOCATED - JUST ONE BLOCK EXISTS AT 0x50000
    assert_that((uint32_t)pmm_addr_list.head == 0x50000);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // NO SLABS ARE ALLOCATED
    assert_that(partial_slabs.head == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    void *result = slab_alloc_c(1);

    ////////////////////
    // SLAB ALLOCATED AT BOTTOM OF MEMORY
    assert_that(result == (void*)0x50000);
 
    ////////////////////
    // ONE KiB IS ALLOCATED - JUST ONE BLOCK EXISTS, NOW AT 0x50400
    assert_that((uint32_t)pmm_addr_list.head == 0x50400);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // ALLOCATED = ONE PARTIAL SLAB, NO FULL SLABS
    assert_that(partial_slabs.head->next == (ListNode*)&partial_slabs.tail);    
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    slab_free_c(result, 1);

    ////////////////////
    // NO MEMORY IS ALLOCATED - JUST ONE BLOCK EXISTS AT 0x50000
    assert_that((uint32_t)pmm_addr_list.head == 0x50000);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // NO SLABS ARE ALLOCATED
    assert_that(partial_slabs.head == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    return RTEST_PASS;
}

static int test_free_two_blocks() {
    ////////////////////
    // NO MEMORY IS ALLOCATED - JUST ONE BLOCK EXISTS AT 0x50000
    assert_that((uint32_t)pmm_addr_list.head == 0x50000);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // NO SLABS ARE ALLOCATED
    assert_that(partial_slabs.head == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    void *result1 = slab_alloc_c(1);

    ////////////////////
    // SLAB ALLOCATED AT BOTTOM OF MEMORY
    assert_that(result1 == (void*)0x50000);
 
    ////////////////////
    // ALLOCATED BITMAP METADATA IS CORRECT
    Slab* meta = slab_metadata(result1);
    assert_that(meta->bitmap == 0x80000001);

    ////////////////////
    // ONE KiB IS ALLOCATED - JUST ONE BLOCK EXISTS, NOW AT 0x50400
    assert_that((uint32_t)pmm_addr_list.head == 0x50400);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // ALLOCATED = ONE PARTIAL SLAB, NO FULL SLABS
    assert_that(partial_slabs.head->next == (ListNode*)&partial_slabs.tail);    
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    void *result2 = slab_alloc_c(2);

    ////////////////////
    // ALLOCATED BITMAP METADATA IS (STILL) CORRECT
    assert_that(meta->bitmap == 0x80000007);

    ////////////////////
    // SLAB ALLOCATED AT NEXT BLOCK
    assert_that(result2 == (void*)0x50020);
 
    ////////////////////
    // STILL ONE KiB IS ALLOCATED - JUST ONE BLOCK EXISTS, NOW AT 0x50400
    assert_that((uint32_t)pmm_addr_list.head == 0x50400);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // STILL ALLOCATED = ONE PARTIAL SLAB, NO FULL SLABS
    assert_that(partial_slabs.head->next == (ListNode*)&partial_slabs.tail);    
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    slab_free_c(result1, 1);

    // ALLOCATED BITMAP METADATA IS CORRECT
    assert_that(meta->bitmap == 0x80000006);

    ////////////////////
    // STILL ONE KiB IS ALLOCATED - JUST ONE BLOCK EXISTS, NOW AT 0x50400
    assert_that((uint32_t)pmm_addr_list.head == 0x50400);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // STILL ALLOCATED = ONE PARTIAL SLAB, NO FULL SLABS
    assert_that(partial_slabs.head->next == (ListNode*)&partial_slabs.tail);    
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    slab_free_c(result2, 2);

    ////////////////////
    // NO MEMORY IS ALLOCATED - JUST ONE BLOCK EXISTS AT 0x50000
    assert_that((uint32_t)pmm_addr_list.head == 0x50000);
    assert_that((ListNode*)pmm_addr_list.head->next == (ListNode*)&pmm_addr_list.tail);

    ////////////////////
    // NO SLABS ARE ALLOCATED
    assert_that(partial_slabs.head == (ListNode*)&partial_slabs.tail);
    assert_that(full_slabs.head == (ListNode*)&full_slabs.tail);

    return RTEST_PASS;
}



static void setup() {
    pmm_init();
    pmm_free(0x50000, 0x8000);
    slab_init();
}

static RTest tests[] = {
    { "/slab/alloc_31_blocks",              test_alloc_31_blocks,               setup,       NULL },

    { "/slab/alloc_zero",                   test_alloc_zero,                    setup,       NULL },
    { "/slab/alloc_over_32",                test_alloc_over_31,                 setup,       NULL },
    { "/slab/alloc_one_new_slab",           test_alloc_one_new_slab,            setup,       NULL },
    { "/slab/alloc_two_blocks",             test_alloc_two_blocks,              setup,       NULL },




    { "/slab/alloc_two_blocks_separately",  test_alloc_two_blocks_separately,   setup,       NULL },
    { "/slab/alloc_two_slabs",              test_alloc_two_slabs,               setup,       NULL },

    { "/slab/free_one_new_slab",            test_free_one_new_slab,             setup,       NULL },
    { "/slab/free_one_two_blocks",          test_free_two_blocks,               setup,       NULL },

    { NULL, NULL, NULL, NULL },
};

void slab_suite(void) {
    rtest_main(tests);
}
