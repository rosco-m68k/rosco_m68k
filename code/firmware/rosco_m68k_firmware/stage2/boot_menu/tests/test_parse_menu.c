#include <string.h>

#include "unity.h"
#include "parse_menu.h"

#define TEST_VALID_EXIT                     "Text:exit"
#define TEST_VALID_ROMFS                    "Text:rom/one"

#define TEST_VALID_EXIT_TRAILING_NEWLINE    "Text:exit\n"
#define TEST_VALID_EXIT_TRAILING_GARBAGE    "Text:exitwhatever"
#define TEST_VALID_ROM_TRAILING_NEWLINE     "Text:rom/one\n"
#define TEST_VALID_ROM_TWO_ITEMS            "Text 1:rom/one\nText 2:rom/two"
#define TEST_VALID_ROM_TWO_NEWLINE          "Text 1:rom/one\nText 2:rom/two\n"

#define TEST_NO_SEPARATOR                   "No separator"
#define TEST_NO_TEXT                        ":exit"
#define TEST_INVALID_TYPE                   "Invalid:blah"
#define TEST_TWO_COLONS                     "Text:rom/one:after colon"

#define TEST_ONE_AT_LIMIT_TEXT              "123456789^123456789^123456789^123456789^:rom/one"
#define TEST_ONE_TOO_LONG_TEXT              "123456789^123456789^123456789^123456789^1:rom/one"
#define TEST_ONE_AT_LIMIT_DATA              "Test:rom/123456789^123456789^123456789^123456789^123456789^123456789^"
#define TEST_ONE_TOO_LONG_DATA              "Test:rom/123456789^123456789^123456789^123456789^123456789^123456789^1"

#define TEST_TOO_MANY_ITEMS                 "0:rom/0\n1:rom/1\n2:rom/2\n3:rom/3\n4:rom/4\n5:rom/5\n6:rom/6\n7:rom/7\n8:rom/8\n9:rom/9\n10:rom/10\n11:rom/11\n12:rom/12\n13:rom/13\n14:rom/14\n15:rom/15\n"

static MenuItem output[15];
static char *buffer[1024];
static int out_num;

void setUp(void) {
    memset(output, 0, sizeof(output));
}

void tearDown(void) {
}

/* *************************************************************************************************** */
/* *************************************************************************************************** */
/* *************************************************************************************************** */

void test_parse_menu_no_input(void) {
    bool result = parse_menu(NULL, 0, 15, output, &out_num);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_zero_input_len(void) {
    bool result = parse_menu(TEST_VALID_ROMFS, 0, 15, output, &out_num);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_zero_max_items(void) {
    bool result = parse_menu(TEST_VALID_ROMFS, strlen(TEST_VALID_ROMFS), 0, output, &out_num);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_no_output(void) {
    bool result = parse_menu(TEST_VALID_ROMFS, strlen(TEST_VALID_ROMFS), 15, NULL, &out_num);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_no_out_num(void) {
    bool result = parse_menu(TEST_VALID_ROMFS, strlen(TEST_VALID_ROMFS), 15, output, NULL);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_one_no_separator(void) {
    bool result = parse_menu(TEST_NO_SEPARATOR, strlen(TEST_NO_SEPARATOR), 15, output, &out_num);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_one_no_text(void) {
    bool result = parse_menu(TEST_NO_TEXT, strlen(TEST_NO_TEXT), 15, output, &out_num);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_one_invalid_type(void) {
    bool result = parse_menu(TEST_INVALID_TYPE, strlen(TEST_INVALID_TYPE), 15, output, &out_num);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_one_valid_exit(void) {
    bool result = parse_menu(TEST_VALID_EXIT, strlen(TEST_VALID_EXIT), 15, output, &out_num);

    TEST_ASSERT_TRUE(result);

    TEST_ASSERT_EQUAL_INT(1, out_num);

    TEST_ASSERT_EQUAL_STRING("Text", output[0].text);
    TEST_ASSERT_EQUAL_STRING("", output[0].data);
    TEST_ASSERT_EQUAL_INT(MENU_ITEM_EXIT, output[0].type);
}

void test_parse_menu_one_valid_exit_trailing_newline(void) {
    bool result = parse_menu(TEST_VALID_EXIT_TRAILING_NEWLINE, strlen(TEST_VALID_EXIT_TRAILING_NEWLINE), 15, output, &out_num);

    TEST_ASSERT_TRUE(result);

    TEST_ASSERT_EQUAL_INT(1, out_num);

    TEST_ASSERT_EQUAL_STRING("Text", output[0].text);
    TEST_ASSERT_EQUAL_STRING("", output[0].data);
    TEST_ASSERT_EQUAL_INT(MENU_ITEM_EXIT, output[0].type);
}

void test_parse_menu_one_valid_exit_trailing_garbage(void) {
    bool result = parse_menu(TEST_VALID_EXIT_TRAILING_GARBAGE, strlen(TEST_VALID_EXIT_TRAILING_GARBAGE), 15, output, &out_num);

    TEST_ASSERT_TRUE(result);

    TEST_ASSERT_EQUAL_INT(1, out_num);

    TEST_ASSERT_EQUAL_STRING("Text", output[0].text);
    TEST_ASSERT_EQUAL_STRING("", output[0].data);
    TEST_ASSERT_EQUAL_INT(MENU_ITEM_EXIT, output[0].type);
}

void test_parse_menu_one_valid_romfs(void) {
    bool result = parse_menu(TEST_VALID_ROMFS, strlen(TEST_VALID_ROMFS), 15, output, &out_num);

    TEST_ASSERT_TRUE(result);

    TEST_ASSERT_EQUAL_INT(1, out_num);

    TEST_ASSERT_EQUAL_STRING("Text", output[0].text);
    TEST_ASSERT_EQUAL_STRING("one", output[0].data);
    TEST_ASSERT_EQUAL_INT(MENU_ITEM_ROMFS, output[0].type);
}

void test_parse_menu_one_valid_romfs_trailing_newline(void) {
    bool result = parse_menu(TEST_VALID_ROM_TRAILING_NEWLINE, strlen(TEST_VALID_ROM_TRAILING_NEWLINE), 15, output, &out_num);

    TEST_ASSERT_TRUE(result);

    TEST_ASSERT_EQUAL_INT(1, out_num);

    TEST_ASSERT_EQUAL_STRING("Text", output[0].text);
    TEST_ASSERT_EQUAL_STRING("one", output[0].data);
    TEST_ASSERT_EQUAL_INT(MENU_ITEM_ROMFS, output[0].type);
}

void test_parse_menu_one_valid_romfs_two_items(void) {
    bool result = parse_menu(TEST_VALID_ROM_TWO_ITEMS, strlen(TEST_VALID_ROM_TWO_ITEMS), 15, output, &out_num);

    TEST_ASSERT_TRUE(result);

    TEST_ASSERT_EQUAL_INT(2, out_num);

    TEST_ASSERT_EQUAL_STRING("Text 1", output[0].text);
    TEST_ASSERT_EQUAL_STRING("one", output[0].data);
    TEST_ASSERT_EQUAL_INT(MENU_ITEM_ROMFS, output[0].type);

    TEST_ASSERT_EQUAL_STRING("Text 2", output[1].text);
    TEST_ASSERT_EQUAL_STRING("two", output[1].data);
    TEST_ASSERT_EQUAL_INT(MENU_ITEM_ROMFS, output[1].type);
}

void test_parse_menu_romfs_at_limit_text(void) {
    bool result = parse_menu(TEST_ONE_AT_LIMIT_TEXT, strlen(TEST_ONE_AT_LIMIT_TEXT), 15, output, &out_num);

    TEST_ASSERT_TRUE(result);

    TEST_ASSERT_EQUAL_INT(1, out_num);

    TEST_ASSERT_EQUAL_STRING("123456789^123456789^123456789^123456789^", output[0].text);
    TEST_ASSERT_EQUAL_STRING("one", output[0].data);
    TEST_ASSERT_EQUAL_INT(MENU_ITEM_ROMFS, output[0].type);
}

void test_parse_menu_romfs_too_long_text(void) {
    bool result = parse_menu(TEST_ONE_TOO_LONG_TEXT, strlen(TEST_ONE_TOO_LONG_TEXT), 15, output, &out_num);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_romfs_at_limit_data(void) {
    bool result = parse_menu(TEST_ONE_AT_LIMIT_DATA, strlen(TEST_ONE_AT_LIMIT_DATA), 15, output, &out_num);

    TEST_ASSERT_TRUE(result);

    TEST_ASSERT_EQUAL_INT(1, out_num);

    TEST_ASSERT_EQUAL_STRING("Test", output[0].text);
    TEST_ASSERT_EQUAL_STRING("123456789^123456789^123456789^123456789^123456789^123456789^", output[0].data);
    TEST_ASSERT_EQUAL_INT(MENU_ITEM_ROMFS, output[0].type);
}

void test_parse_menu_romfs_too_long_data(void) {
    bool result = parse_menu(TEST_ONE_TOO_LONG_TEXT, strlen(TEST_ONE_TOO_LONG_TEXT), 15, output, &out_num);

    TEST_ASSERT_FALSE(result);
}

void test_parse_menu_romfs_too_many_items(void) {
    bool result = parse_menu(TEST_TOO_MANY_ITEMS, strlen(TEST_TOO_MANY_ITEMS), 15, output, &out_num);

    TEST_ASSERT_TRUE(result);

    TEST_ASSERT_EQUAL_INT(15, out_num);

    char buf[3];

    for (int i = 0; i < 15; i++) {
        snprintf(buf, 3, "%d", i);

        TEST_ASSERT_EQUAL_STRING(buf, output[i].text);
        TEST_ASSERT_EQUAL_STRING(buf, output[i].data);
        TEST_ASSERT_EQUAL_INT(MENU_ITEM_ROMFS, output[i].type);
    }
}


int main(void) {
    UNITY_BEGIN();

    RUN_TEST(test_parse_menu_no_input);
    RUN_TEST(test_parse_menu_zero_max_items);
    RUN_TEST(test_parse_menu_no_output);
    RUN_TEST(test_parse_menu_no_out_num);

    RUN_TEST(test_parse_menu_one_no_separator);
    RUN_TEST(test_parse_menu_one_no_text);
    RUN_TEST(test_parse_menu_one_invalid_type);

    RUN_TEST(test_parse_menu_one_valid_exit);
    RUN_TEST(test_parse_menu_one_valid_exit_trailing_newline);
    RUN_TEST(test_parse_menu_one_valid_exit_trailing_garbage);

    RUN_TEST(test_parse_menu_one_valid_romfs);
    RUN_TEST(test_parse_menu_one_valid_romfs_trailing_newline);

    RUN_TEST(test_parse_menu_one_valid_romfs_two_items);

    RUN_TEST(test_parse_menu_romfs_at_limit_text);
    RUN_TEST(test_parse_menu_romfs_too_long_text);
    RUN_TEST(test_parse_menu_romfs_at_limit_data);
    RUN_TEST(test_parse_menu_romfs_too_long_data);

    RUN_TEST(test_parse_menu_romfs_too_many_items);

    return UNITY_END();
}
