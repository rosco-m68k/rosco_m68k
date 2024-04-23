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
 * Unit tests: interrupts
 * ------------------------------------------------------------
 */
#include <stdint.h>
#include <stdbool.h>

#include "roscotest.h"
#include "list.h"
#include "kmachine.h"

extern List irq_1_list;
extern List irq_2_list;
extern List irq_3_list;
extern List irq_4_list;
extern List irq_5_list;
extern List irq_6_list;
extern List irq_7_list;

static uint8_t nums[4];
static uint8_t numi;

static void* test_data_0 = (void*)0x00000055;
static void* test_data_1 = (void*)0x000000AA;

#define assert_empty(list)                                  \
    do {                                                    \
        assert_that(list.head == (ListNode*)&list.tail);    \
    } while (0)

#define assert_not_empty(list)                              \
    do {                                                    \
        assert_that(list.head != (ListNode*)&list.tail);    \
    } while (0)

#define assert_nums(val0, val1, val2, val3)             \
    do {                                                \
        assert_that(nums[0] == val0);                   \
        assert_that(nums[1] == val1);                   \
        assert_that(nums[2] == val2);                   \
        assert_that(nums[3] == val3);                   \
    } while (0)


static bool test_handler_empty_false(uint8_t irq, void* data) {
    return false;
}

static bool test_handler_one_false(uint8_t irq, void *data) {
    nums[numi++] = 1;
    return false;
}

static bool test_handler_two_false(uint8_t irq, void *data) {
    nums[numi++] = 2;
    return false;
}

static bool test_handler_two_true(uint8_t irq, void *data) {
    nums[numi++] = 2;
    return true;
}

static bool test_handler_three_false(uint8_t irq, void *data) {
    nums[numi++] = 3;
    return false;
}

static bool test_handler_data_test(uint8_t irq, void *data) {
    nums[numi++] = irq;
    nums[numi++] = ((uint32_t)data) & 0xFF;
    return false;
}

static int test_register_irq_1() {
    assert_empty(irq_1_list);

    IrqHandler handler;

    handler.handler = test_handler_empty_false;

    irq_register_c(1, &handler);

    assert_not_empty(irq_1_list);

    assert_empty(irq_2_list);
    assert_empty(irq_3_list);
    assert_empty(irq_4_list);
    assert_empty(irq_5_list);
    assert_empty(irq_6_list);
    assert_empty(irq_7_list);

    return RTEST_PASS;
}

static int test_register_irq_2() {
    assert_empty(irq_2_list);

    IrqHandler handler;

    handler.handler = test_handler_empty_false;

    irq_register_c(2, &handler);

    assert_empty(irq_1_list);

    assert_not_empty(irq_2_list);

    assert_empty(irq_3_list);
    assert_empty(irq_4_list);
    assert_empty(irq_5_list);
    assert_empty(irq_6_list);
    assert_empty(irq_7_list);

    return RTEST_PASS;
}

static int test_register_irq_3() {
    assert_empty(irq_3_list);

    IrqHandler handler;

    handler.handler = test_handler_empty_false;

    irq_register_c(3, &handler);

    assert_empty(irq_1_list);
    assert_empty(irq_2_list);
    
    assert_not_empty(irq_3_list);

    assert_empty(irq_4_list);
    assert_empty(irq_5_list);
    assert_empty(irq_6_list);
    assert_empty(irq_7_list);

    return RTEST_PASS;
}

static int test_register_irq_4() {
    assert_empty(irq_4_list);

    IrqHandler handler;

    handler.handler = test_handler_empty_false;

    irq_register_c(4, &handler);

    assert_empty(irq_1_list);
    assert_empty(irq_2_list);
    assert_empty(irq_3_list);
    
    assert_not_empty(irq_4_list);

    assert_empty(irq_5_list);
    assert_empty(irq_6_list);
    assert_empty(irq_7_list);

    return RTEST_PASS;
}

static int test_register_irq_5() {
    assert_empty(irq_5_list);

    IrqHandler handler;

    handler.handler = test_handler_empty_false;

    irq_register_c(5, &handler);

    assert_empty(irq_1_list);
    assert_empty(irq_2_list);
    assert_empty(irq_3_list);
    assert_empty(irq_4_list);
    
    assert_not_empty(irq_5_list);

    assert_empty(irq_6_list);
    assert_empty(irq_7_list);

    return RTEST_PASS;
}

static int test_register_irq_6() {
    assert_empty(irq_6_list);

    IrqHandler handler;

    handler.handler = test_handler_empty_false;

    irq_register_c(6, &handler);

    assert_empty(irq_1_list);
    assert_empty(irq_2_list);
    assert_empty(irq_3_list);
    assert_empty(irq_4_list);
    assert_empty(irq_5_list);
    
    assert_not_empty(irq_6_list);

    assert_empty(irq_7_list);

    return RTEST_PASS;
}

static int test_register_irq_7() {
    assert_empty(irq_7_list);

    IrqHandler handler;

    handler.handler = test_handler_empty_false;

    irq_register_c(7, &handler);

    assert_empty(irq_1_list);
    assert_empty(irq_2_list);
    assert_empty(irq_3_list);
    assert_empty(irq_4_list);
    assert_empty(irq_5_list);
    assert_empty(irq_6_list);
    
    assert_not_empty(irq_7_list);

    return RTEST_PASS;
}

static int test_remove() {
    assert_empty(irq_7_list);

    IrqHandler handler;

    handler.handler = test_handler_empty_false;

    irq_register_c(7, &handler);
    
    assert_not_empty(irq_7_list);

    irq_remove_c(&handler);

    assert_empty(irq_7_list);

    return RTEST_PASS;
}

void run_handler_chain_c(uint8_t irq);

static int test_run_chain_zero() {
    run_handler_chain_c(0);

    // no crash is a pass
    return RTEST_PASS;
}

static int test_run_chain_eight() {
    run_handler_chain_c(8);

    // no crash is a pass
    return RTEST_PASS;
}

static int test_run_chain_empty() {
    run_handler_chain_c(1);

    // no crash is a pass
    return RTEST_PASS;
}

static int test_run_chain_one_none_succeed() {
    IrqHandler handler;

    handler.handler = test_handler_one_false;
    irq_register_c(1, &handler);

    run_handler_chain_c(1);

    assert_nums(1, 0, 0, 0);

    // normal return / no crash is a pass
    return RTEST_PASS;
}

static int test_run_chain_three_none_succeed() {
    IrqHandler handler0;
    IrqHandler handler1;
    IrqHandler handler2;

    handler0.handler = test_handler_one_false;
    handler1.handler = test_handler_two_false;
    handler2.handler = test_handler_three_false;
    irq_register_c(1, &handler0);
    irq_register_c(1, &handler1);
    irq_register_c(1, &handler2);

    run_handler_chain_c(1);

    assert_nums(1, 2, 3, 0);

    return RTEST_PASS;
}

static int test_run_chain_three_two_succeeds() {
    IrqHandler handler0;
    IrqHandler handler1;
    IrqHandler handler2;

    handler0.handler = test_handler_one_false;
    handler1.handler = test_handler_two_true;
    handler2.handler = test_handler_three_false;
    irq_register_c(1, &handler0);
    irq_register_c(1, &handler1);
    irq_register_c(1, &handler2);

    run_handler_chain_c(1);

    // Three never gets run, because two succeeds
    assert_nums(1, 2, 0, 0);

    return RTEST_PASS;
}

static int test_run_chain_correct_data_1() {
    IrqHandler handler0;
    IrqHandler handler1;

    handler0.handler = test_handler_data_test;
    handler0.data = test_data_0;
    handler1.handler = test_handler_data_test;
    handler1.data = test_data_1;

    irq_register_c(1, &handler0);
    irq_register_c(1, &handler1);

    run_handler_chain_c(1);

    assert_nums(1, 0x55, 1, 0xaa);

    return RTEST_PASS;
}

static int test_run_chain_correct_data_5() {
    IrqHandler handler0;
    IrqHandler handler1;

    handler0.handler = test_handler_data_test;
    handler0.data = test_data_0;
    handler1.handler = test_handler_data_test;
    handler1.data = test_data_1;

    irq_register_c(5, &handler0);
    irq_register_c(5, &handler1);

    run_handler_chain_c(5);

    assert_nums(5, 0x55, 5, 0xaa);

    return RTEST_PASS;
}

static void setup() {
    irq_init();

    nums[0] = 0;
    nums[1] = 0;
    nums[2] = 0;
    nums[3] = 0;
    numi = 0;
}

static RTest tests[] = {
    { "/irq/register_1",                    test_register_irq_1,                setup,              NULL },
    { "/irq/register_2",                    test_register_irq_2,                setup,              NULL },
    { "/irq/register_3",                    test_register_irq_3,                setup,              NULL },
    { "/irq/register_4",                    test_register_irq_4,                setup,              NULL },
    { "/irq/register_5",                    test_register_irq_5,                setup,              NULL },
    { "/irq/register_6",                    test_register_irq_6,                setup,              NULL },
    { "/irq/register_7",                    test_register_irq_7,                setup,              NULL },

    { "/irq/remove",                        test_remove,                        setup,              NULL },

    { "/irq/run_chain_zero",                test_run_chain_zero,                setup,              NULL },
    { "/irq/run_chain_eight",               test_run_chain_eight,               setup,              NULL },
    { "/irq/run_chain_empty",               test_run_chain_empty,               setup,              NULL },
    { "/irq/run_chain_one_none_succeed",    test_run_chain_one_none_succeed,    setup,              NULL },
    { "/irq/run_chain_one_none_succeed",    test_run_chain_one_none_succeed,    setup,              NULL },
    { "/irq/run_chain_three_none_succeed",  test_run_chain_three_none_succeed,  setup,              NULL },
    { "/irq/run_chain_three_two_succeeds",  test_run_chain_three_two_succeeds,  setup,              NULL },

    { "/irq/run_chain_argument_test_irq1",  test_run_chain_correct_data_1,      setup,              NULL },
    { "/irq/run_chain_argument_test_irq5",  test_run_chain_correct_data_5,      setup,              NULL },

    { NULL, NULL, NULL, NULL },
};

void interrupts_suite(void) {
    rtest_main(tests);
}