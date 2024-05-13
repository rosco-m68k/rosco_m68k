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
 * Unit tests: bitmap
 * ------------------------------------------------------------
 */

#include "roscotest.h"
#include "bitmap.h"

static uint32_t bitmap[4];

#define assert_bitmap(val0, val1, val2, val3)           \
    do {                                                \
        assert_that(bitmap[0] == val0);                 \
        assert_that(bitmap[1] == val1);                 \
        assert_that(bitmap[2] == val2);                 \
        assert_that(bitmap[3] == val3);                 \
    } while (0)

static int test_bitmap_set() {
    assert_bitmap(0, 0, 0, 0);

    bitmap_set_c(bitmap, 0);
    assert_bitmap(0x00000001, 0x00000000, 0x00000000, 0x00000000);

    bitmap_set_c(bitmap, 1);
    assert_bitmap(0x00000003, 0x00000000, 0x00000000, 0x00000000);

    bitmap_set_c(bitmap, 31);
    assert_bitmap(0x80000003, 0x00000000, 0x00000000, 0x00000000);

    bitmap_set_c(bitmap, 31);
    assert_bitmap(0x80000003, 0x00000000, 0x00000000, 0x00000000);

    bitmap_set_c(bitmap, 32);
    assert_bitmap(0x80000003, 0x00000001, 0x00000000, 0x00000000);

    bitmap_set_c(bitmap, 63);
    assert_bitmap(0x80000003, 0x80000001, 0x00000000, 0x00000000);

    bitmap_set_c(bitmap, 72);
    assert_bitmap(0x80000003, 0x80000001, 0x00000100, 0x00000000);

    bitmap_set_c(bitmap, 72);
    assert_bitmap(0x80000003, 0x80000001, 0x00000100, 0x00000000);

    bitmap_set_c(bitmap, 127);
    assert_bitmap(0x80000003, 0x80000001, 0x00000100, 0x80000000);

    return RTEST_PASS;
}

static int test_bitmap_clear() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_clear_c(bitmap, 0);
    assert_bitmap(0xFFFFFFFE, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_clear_c(bitmap, 1);
    assert_bitmap(0xFFFFFFFC, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_clear_c(bitmap, 31);
    assert_bitmap(0x7FFFFFFC, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_clear_c(bitmap, 31);
    assert_bitmap(0x7FFFFFFC, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_clear_c(bitmap, 32);
    assert_bitmap(0x7FFFFFFC, 0xFFFFFFFE, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_clear_c(bitmap, 63);
    assert_bitmap(0x7FFFFFFC, 0x7FFFFFFE, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_clear_c(bitmap, 72);
    assert_bitmap(0x7FFFFFFC, 0x7FFFFFFE, 0xFFFFFEFF, 0xFFFFFFFF);

    bitmap_clear_c(bitmap, 72);
    assert_bitmap(0x7FFFFFFC, 0x7FFFFFFE, 0xFFFFFEFF, 0xFFFFFFFF);

    bitmap_clear_c(bitmap, 127);
    assert_bitmap(0x7FFFFFFC, 0x7FFFFFFE, 0xFFFFFEFF, 0x7FFFFFFF);

    return RTEST_PASS;
}

static int test_bitmap_flip() {
    assert_bitmap(0, 0, 0, 0);

    bitmap_flip_c(bitmap, 0);
    assert_bitmap(0x00000001, 0x00000000, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 0);
    assert_bitmap(0x00000000, 0x00000000, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 0);
    assert_bitmap(0x00000001, 0x00000000, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 1);
    assert_bitmap(0x00000003, 0x00000000, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 31);
    assert_bitmap(0x80000003, 0x00000000, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 31);
    assert_bitmap(0x00000003, 0x00000000, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 31);
    assert_bitmap(0x80000003, 0x00000000, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 32);
    assert_bitmap(0x80000003, 0x00000001, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 63);
    assert_bitmap(0x80000003, 0x80000001, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 72);
    assert_bitmap(0x80000003, 0x80000001, 0x00000100, 0x00000000);

    bitmap_flip_c(bitmap, 72);
    assert_bitmap(0x80000003, 0x80000001, 0x00000000, 0x00000000);

    bitmap_flip_c(bitmap, 72);
    assert_bitmap(0x80000003, 0x80000001, 0x00000100, 0x00000000);

    bitmap_flip_c(bitmap, 127);
    assert_bitmap(0x80000003, 0x80000001, 0x00000100, 0x80000000);

    bitmap_flip_c(bitmap, 127);
    assert_bitmap(0x80000003, 0x80000001, 0x00000100, 0x00000000);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_none() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == -1);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_zero() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 0);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 0);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_one() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 1);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 1);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_seven() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 7);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 7);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_eight() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 8);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 8);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_twelve() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 12);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 12);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_fifteen() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 15);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 15);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_sixteen() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 16);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 16);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_twtythree() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 23);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 23);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_twtyfour() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 24);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 24);

    return RTEST_PASS;
}

static int test_bitmap_find_clear_thtyone() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 31);

    int8_t result = bitmap_find_clear_c(bitmap[0]);
    assert_that(result == 31);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_none_0() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 2);
    assert_that(result == -1);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_none_1() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 0);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 2);
    assert_that(result == -1);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_one_zero() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 0);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 1);
    assert_that(result == 0);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_two_zero() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 0);
    bitmap_flip_c(bitmap, 1);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 2);
    assert_that(result == 0);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_three_zero() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 0);
    bitmap_flip_c(bitmap, 1);
    bitmap_flip_c(bitmap, 2);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 3);
    assert_that(result == 0);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_one_one() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 1);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 1);
    assert_that(result == 1);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_two_one() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 1);
    bitmap_flip_c(bitmap, 2);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 2);
    assert_that(result == 1);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_three_one() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 1);
    bitmap_flip_c(bitmap, 2);
    bitmap_flip_c(bitmap, 3);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 3);
    assert_that(result == 1);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_one_thtyone() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 31);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 1);
    assert_that(result == 31);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_two_thty() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 30);
    bitmap_flip_c(bitmap, 31);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 2);
    assert_that(result == 30);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_three_twtynine() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 29);
    bitmap_flip_c(bitmap, 30);
    bitmap_flip_c(bitmap, 31);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 3);
    assert_that(result == 29);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_zero_n() {
    assert_bitmap(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

    bitmap_flip_c(bitmap, 0);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], -1);
    assert_that(result == -1);

    return RTEST_PASS;
}

static int test_bitmap_find_n_clear_thtytwo_n() {
    assert_bitmap(0, 0, 0, 0);

    int8_t result = bitmap_find_n_clear_c(bitmap[0], 32);
    assert_that(result == 0);

    bitmap_flip_c(bitmap, 15);

    result = bitmap_find_n_clear_c(bitmap[0], 32);
    assert_that(result == -1);

    bitmap_flip_c(bitmap, 15);
    bitmap_flip_c(bitmap, 0);

    result = bitmap_find_n_clear_c(bitmap[0], 32);
    assert_that(result == -1);

    bitmap_flip_c(bitmap, 0);
    bitmap_flip_c(bitmap, 31);

    result = bitmap_find_n_clear_c(bitmap[0], 32);
    assert_that(result == -1);

    return RTEST_PASS;
}


static void setup(uint32_t val) {
    bitmap[0] = val;
    bitmap[1] = val;
    bitmap[2] = val;
    bitmap[3] = val;
}

static void setup_zero() {
    setup(0);
}

static void setup_max() {
    setup(0xFFFFFFFF);
}

static RTest tests[] = {
    { "/bitmap/set",                        test_bitmap_set,                            setup_zero,         NULL },
    { "/bitmap/clear",                      test_bitmap_clear,                          setup_max,          NULL },
    { "/bitmap/flip",                       test_bitmap_flip,                           setup_zero,         NULL },
    { "/bitmap/find_clear_none",            test_bitmap_find_clear_none,                setup_max,          NULL },
    { "/bitmap/find_clear_zero",            test_bitmap_find_clear_zero,                setup_max,          NULL },
    { "/bitmap/find_clear_one",             test_bitmap_find_clear_one,                 setup_max,          NULL },
    { "/bitmap/find_clear_seven",           test_bitmap_find_clear_seven,               setup_max,          NULL },
    { "/bitmap/find_clear_eight",           test_bitmap_find_clear_eight,               setup_max,          NULL },
    { "/bitmap/find_clear_twelve",          test_bitmap_find_clear_twelve,              setup_max,          NULL },
    { "/bitmap/find_clear_fifteen",         test_bitmap_find_clear_fifteen,             setup_max,          NULL },
    { "/bitmap/find_clear_sixteen",         test_bitmap_find_clear_sixteen,             setup_max,          NULL },
    { "/bitmap/find_clear_twenty_three",    test_bitmap_find_clear_twtythree,           setup_max,          NULL },
    { "/bitmap/find_clear_twenty_four",     test_bitmap_find_clear_twtyfour,            setup_max,          NULL },
    { "/bitmap/find_clear_thirty_one",      test_bitmap_find_clear_thtyone,             setup_max,          NULL },
    { "/bitmap/find_n_clear_none_0",        test_bitmap_find_n_clear_none_0,            setup_max,          NULL },
    { "/bitmap/find_n_clear_none_1",        test_bitmap_find_n_clear_none_1,            setup_max,          NULL },
    { "/bitmap/find_n_clear_one_zero",      test_bitmap_find_n_clear_one_zero,          setup_max,          NULL },
    { "/bitmap/find_n_clear_two_zero",      test_bitmap_find_n_clear_two_zero,          setup_max,          NULL },
    { "/bitmap/find_n_clear_three_zero",    test_bitmap_find_n_clear_three_zero,        setup_max,          NULL },
    { "/bitmap/find_n_clear_one_one",       test_bitmap_find_n_clear_one_one,           setup_max,          NULL },
    { "/bitmap/find_n_clear_two_one",       test_bitmap_find_n_clear_two_one,           setup_max,          NULL },
    { "/bitmap/find_n_clear_three_one",     test_bitmap_find_n_clear_three_one,         setup_max,          NULL },
    { "/bitmap/find_n_clear_one_31",        test_bitmap_find_n_clear_one_thtyone,       setup_max,          NULL },
    { "/bitmap/find_n_clear_two_30",        test_bitmap_find_n_clear_two_thty,          setup_max,          NULL },
    { "/bitmap/find_n_clear_three_29",      test_bitmap_find_n_clear_three_twtynine,    setup_max,          NULL },
    { "/bitmap/find_n_clear_zero_n",        test_bitmap_find_n_clear_zero_n,            setup_max,          NULL },
    { "/bitmap/find_n_clear_thtytwo_n",     test_bitmap_find_n_clear_thtytwo_n,         setup_zero,         NULL },
    { NULL, NULL, NULL, NULL },
};

void bitmap_suite(void) {
    rtest_main(tests);
}