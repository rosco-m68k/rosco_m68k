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
 * rosco_m68k tiny unit testing framework
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_RTEST_H
#define _ROSCOM68K_RTEST_H

#ifndef rt_printf
#include <stdio.h>
#define rt_printf(...)   printf(__VA_ARGS__)
#endif

#define RTEST_PASS      1
#define RTEST_FAIL      -1

#define RTEST_FAIL_TEST(msg)                                                    \
    do {                                                                        \
        rt_printf("\033[0;37m[\033[1;31mFAIL\033[0;37m]: ");                    \
        rt_printf((msg));                                                       \
        rt_printf(" [%s:%d]", __FILE__, __LINE__);                              \
        rt_printf("\n");                                                        \
        return RTEST_FAIL;                                                      \
    } while (0)                                                                 \

#define rtest_assert_that(expr)                                                 \
    if (!(expr)) {                                                              \
        RTEST_FAIL_TEST("(" #expr ") is false");                                \
    }

#define rtest_assert_true(expr)         rtest_assert_that(expr)
#define rtest_assert_false(expr)        rtest_assert_that((!(expr)))

#ifndef RTEST_ONLY_NAMESPACED_ASSERTS
#   define assert_that(...)             rtest_assert_that(__VA_ARGS__)
#   define assert_true(...)             rtest_assert_true(__VA_ARGS__)
#   define assert_false(...)            rtest_assert_false(__VA_ARGS__)
#endif

#define rtest_main(tests)                                                                       \
    do {                                                                                        \
        int __rt_total = 0;                                                                     \
        int __rt_pass = 0;                                                                      \
        int __rt_fail = 0;                                                                      \
        for (RTest *test = &tests[0]; test->test_func != NULL; test++) {                        \
            __rt_total += 1;                                                                    \
            rt_printf("\033[1;37m%-40s", test->name == NULL ? "<unnamed test>" : test->name);   \
            if (test->setup_func != NULL) {                                                     \
                test->setup_func();                                                             \
            }                                                                                   \
            int test_result = test->test_func();                                                \
            if (test_result == RTEST_PASS) {                                                    \
                rt_printf("\033[0m[\033[1;32mPASS\033[0m]\n");                                  \
                __rt_pass += 1;                                                                 \
            } else if (test_result == RTEST_FAIL) {                                             \
                __rt_fail += 1;                                                                 \
            } else {                                                                            \
                rt_printf("\033[0m[\033[1;33m????\033[0m]");                                    \
                rt_printf(": (missing return statement?)\n");                                   \
            }                                                                                   \
            if (test->teardown_func != NULL) {                                                  \
                test->teardown_func();                                                          \
            }                                                                                   \
        }                                                                                       \
        rt_printf("\033[0mCompleted \033[1;37m%d \033[0mtests; \033[1;32m", __rt_total);       \
        rt_printf("%d \033[0mpassed; ", __rt_pass);                                             \
        rt_printf(__rt_fail == 0 ? "\033[1;32m" : "\033[1;31m");                                \
        rt_printf("%d \033[0mfailed\n", __rt_fail);                                             \
    } while (0)

typedef struct {
    const char *name;
    int (*test_func)(void);
    void (*setup_func)(void);
    void (*teardown_func)(void);
} RTest;

#endif//_ROSCOM68K_RTEST_H
