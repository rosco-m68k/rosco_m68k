#include "unity.h"
#include "backend.h"
#include "xosera_blit_rects.h"

void setUp(void) {
}

void tearDown(void) {
}

/* *************************************************************************************************** */
/* *************************************************************************************************** */
/* *************************************************************************************************** */

void test_start_word_0_0_lw0(void) {
    Rect rect = { .x = 0, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0);

    TEST_ASSERT_EQUAL_HEX16(0x0000, result);
}


void test_start_word_0_0_lw1(void) {
    Rect rect = { .x = 0, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0);

    TEST_ASSERT_EQUAL_HEX16(0x0000, result);
}


void test_start_word_1_0_lw1(void) {
    Rect rect = { .x = 1, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 1);

    TEST_ASSERT_EQUAL_HEX16(0x0000, result);
}


void test_start_word_0_1_lw1(void) {
    Rect rect = { .x = 0, .y = 1, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 1);

    TEST_ASSERT_EQUAL_HEX16(0x0001, result);
}


void test_start_word_0_0_lw100(void) {
    Rect rect = { .x = 0, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x0000, result);
}


void test_start_word_1_0_lw100(void) {
    Rect rect = { .x = 1, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x0000, result);
}


void test_start_word_2_0_lw100(void) {
    Rect rect = { .x = 2, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x0000, result);
}


void test_start_word_3_0_lw100(void) {
    Rect rect = { .x = 3, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x0000, result);
}


void test_start_word_4_0_lw100(void) {
    Rect rect = { .x = 4, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x0001, result);
}


void test_start_word_5_0_lw100(void) {
    Rect rect = { .x = 5, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x0001, result);
}


void test_start_word_6_0_lw100(void) {
    Rect rect = { .x = 6, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x0001, result);
}

void test_start_word_7_0_lw100(void) {
    Rect rect = { .x = 7, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x0001, result);
}

void test_start_word_8_0_lw100(void) {
    Rect rect = { .x = 8, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x0002, result);
}


void test_start_word_1023_0_lw100(void) {
    Rect rect = { .x = 1023, .y = 0, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x000ff, result);
}


void test_start_word_0_1_lw100(void) {
    Rect rect = { .x = 0, .y = 1, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x00100, result);
}


void test_start_word_0_2_lw100(void) {
    Rect rect = { .x = 0, .y = 2, .w = 0, .h = 0 };

    uint16_t result = xosera_rect_start_word(&rect, 0x100);

    TEST_ASSERT_EQUAL_HEX16(0x00200, result);
}



/* *************************************************************************************************** */
/* *************************************************************************************************** */
/* *************************************************************************************************** */

/* ********** 
 * See note in xosera_blit_rects.c for how this all works...
 *
 */
void test_blit_nibble_mask_0x_w0(void) {
    Rect rect = { .x = 0, .y = 0, .w = 0, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0xf000, result);
}

/* ********** 
 *
 *
 *   MMMM.................
 */
void test_blit_nibble_mask_0x_w4(void) {
    Rect rect = { .x = 0, .y = 0, .w = 4, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0xf000, result);
}


/* *************************************************************
 *
 *   ....MMMM.............
 */

void test_blit_nibble_mask_4x_w4(void) {
    Rect rect = { .x = 4, .y = 0, .w = 4, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0xf000, result);
}


/* *************************************************************
 *
 *   eLLLMMMMRRee.........
 */
void test_blit_nibble_mask_1x_w9(void) {
    Rect rect = { .x = 1, .y = 0, .w = 9, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0x7c00, result);
}


/* *************************************************************
 *   eLLLMMMMMMMMRRee.....
 */
void test_blit_nibble_mask_1x_w13(void) {
    Rect rect = { .x = 1, .y = 0, .w = 13, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0x7c00, result);
}


/* *************************************************************
 * In the following tests, it's worth bearing in mind that in
 * the case where the width is 1, the blitter will apply the
 * AND of both the left and right masks... 
 *
 *   Leee.................
 */
void test_blit_nibble_mask_0x_w1(void) {
    Rect rect = { .x = 0, .y = 0, .w = 1, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0xf800, result);    /* applies 0x8000 */
}


/* *************************************************************
 *
 *   eLee.................
 */
void test_blit_nibble_mask_1x_w1(void) {
    Rect rect = { .x = 1, .y = 0, .w = 1, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0x7c00, result);    /* applies 0x4000 */
}


/* *************************************************************
 *
 *   eeLe.................
 */
void test_blit_nibble_mask_2x_w1(void) {
    Rect rect = { .x = 2, .y = 0, .w = 1, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0x3e00, result);    /* applies 0x2000 */
}


/* *************************************************************
 *
 *   eeeL.................
 */
void test_blit_nibble_mask_3x_w1(void) {
    Rect rect = { .x = 3, .y = 0, .w = 1, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0x1000, result);
}


/* *************************************************************
 *
 *   LRee.................
 */
void test_blit_nibble_mask_0x_w2(void) {
    Rect rect = { .x = 0, .y = 0, .w = 2, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0xfc00, result);    /* applies 0xc000 */
}


/* *************************************************************
 *
 *   eLRe.................
 */
void test_blit_nibble_mask_1x_w2(void) {
    Rect rect = { .x = 1, .y = 0, .w = 2, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0x7e00, result);   /* applies 0x6000 */
}


/* *************************************************************
 *
 *   eeLR.................
 */
void test_blit_nibble_mask_2x_w2(void) {
    Rect rect = { .x = 2, .y = 0, .w = 2, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0x3000, result);    /* applies 0x3000 */
}


/* *************************************************************
 *
 *   eeeLReee.............
 */
void test_blit_nibble_mask_3x_w2(void) {
    Rect rect = { .x = 3, .y = 0, .w = 2, .h = 1 };

    uint16_t result = xosera_fill_rect_blit_shift(&rect);
    uint16_t resultv = xosera_fill_rect_blit_shift_v(rect.x, rect.w);

    TEST_ASSERT_EQUAL_HEX16(result, resultv);
    TEST_ASSERT_EQUAL_HEX16(0x1800, result);
}


int main(void) {
    UNITY_BEGIN();

    RUN_TEST(test_start_word_0_0_lw0);
    RUN_TEST(test_start_word_0_0_lw1);
    RUN_TEST(test_start_word_1_0_lw1);
    RUN_TEST(test_start_word_0_1_lw1);
    RUN_TEST(test_start_word_0_0_lw100);
    RUN_TEST(test_start_word_1_0_lw100);
    RUN_TEST(test_start_word_2_0_lw100);
    RUN_TEST(test_start_word_3_0_lw100);
    RUN_TEST(test_start_word_4_0_lw100);
    RUN_TEST(test_start_word_5_0_lw100);
    RUN_TEST(test_start_word_6_0_lw100);
    RUN_TEST(test_start_word_7_0_lw100);
    RUN_TEST(test_start_word_8_0_lw100);
    RUN_TEST(test_start_word_1023_0_lw100);
    RUN_TEST(test_start_word_0_1_lw100);
    RUN_TEST(test_start_word_0_2_lw100);

    RUN_TEST(test_blit_nibble_mask_0x_w0);
    RUN_TEST(test_blit_nibble_mask_0x_w4);
    RUN_TEST(test_blit_nibble_mask_4x_w4);
    RUN_TEST(test_blit_nibble_mask_1x_w9);
    RUN_TEST(test_blit_nibble_mask_1x_w13);
    RUN_TEST(test_blit_nibble_mask_0x_w1);
    RUN_TEST(test_blit_nibble_mask_1x_w1);
    RUN_TEST(test_blit_nibble_mask_2x_w1);
    RUN_TEST(test_blit_nibble_mask_3x_w1);
    RUN_TEST(test_blit_nibble_mask_0x_w2);
    RUN_TEST(test_blit_nibble_mask_1x_w2);
    RUN_TEST(test_blit_nibble_mask_2x_w2);
    RUN_TEST(test_blit_nibble_mask_3x_w2);

    return UNITY_END();
}