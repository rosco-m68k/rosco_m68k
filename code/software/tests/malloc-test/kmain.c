/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * rosco_m68k "kernel main" for bare-metal programs
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <heap.h>
#include <machine.h>

static const char *test = "TESTING!TESTING!TESTING!TESTING!";

extern int newB();
extern int getBNum();
extern int deleteB();

void calloc_check(size_t count, size_t size) {
    printf("calloc zero check      : starting\n");
    size_t total = count * size;
    bool success = true;

    for (unsigned loop = 0; loop < 10 && success; ++loop) {
        unsigned char *check_tmp = calloc(count, size);
        if (!check_tmp) {
            printf("calloc zero check      : failed to calloc(0x%zX, 0x%zX)\n", count, size);
            success = false;
            break;
        }

        for (size_t i = 0; i < total; ++i) {
            if (check_tmp[i] != 0) {
                printf("calloc zero check      : failed at loop %u byte 0x%zX\n", loop, i);
                success = false;
                break;
            }
            check_tmp[i] = i ^ loop;  // Fill with garbage
        }
        free(check_tmp);
    }

    if (success) {
        printf("calloc zero check      : succeeded\n");
    }
}

void calloc_benchmark(size_t count, size_t size) {
    printf("calloc benchmark       : starting\n");
    bool success = true;
    unsigned start_ticks = _TIMER_100HZ;

    for (unsigned loop = 0; loop < 0x80; ++loop) {
        void *ptr = calloc(count, size);
        if (!ptr) {
            printf("calloc benchmark       : failed to calloc(0x%zX, 0x%zX)\n", count, size);
            success = false;
            break;
        }
        free(ptr);
    }

    unsigned end_ticks = _TIMER_100HZ;
    if (success) {
        printf("calloc benchmark       : took %u ticks\n", end_ticks - start_ticks);
    }
}

void realloc_check(size_t size) {
    printf("realloc copy check     : starting\n");
    bool success = true;
    void *current_ptr = NULL;

    for (unsigned loop = 0; loop < 10 && success; ++loop) {
        unsigned char *new_ptr = realloc(current_ptr, size);
        if (!new_ptr) {
            printf("realloc copy check     : failed to realloc(%p, 0x%zX)\n", current_ptr, size);
            success = false;
            break;
        }

        current_ptr = new_ptr;
        for (size_t i = 0; i < size; ++i) {
            if (loop > 0 && new_ptr[i] != (unsigned char) (i ^ (loop - 1))) {
                printf("realloc copy check     : failed copy-check at loop %u byte 0x%zX\n", loop, i);
                success = false;
                break;
            }
            new_ptr[i] = i ^ loop;
        }
    }
    free(current_ptr);

    if (success) {
        printf("realloc copy check     : succeeded\n");
    }
}

void realloc_benchmark(size_t size) {
    printf("realloc benchmark      : starting\n");
    bool success = true;
    void *current_ptr = NULL;
    unsigned start_ticks = _TIMER_100HZ;

    current_ptr = NULL;
    for (unsigned loop = 0; loop < 0x80; ++loop) {
        void *new_ptr = realloc(current_ptr, size);
        if (!new_ptr) {
            printf("realloc benchmark      : failed to realloc(%p, 0x%zX)\n", current_ptr, size);
            success = false;
            break;
        }
        current_ptr = new_ptr;
    }
    free(current_ptr);

    unsigned end_ticks = _TIMER_100HZ;
    if (success) {
        printf("realloc benchmark      : took %u ticks\n", end_ticks - start_ticks);
    }
}

void kmain() {
    printf("C++ new/delete test starting\n");
    
    printf("new operator check     : newB returns    %d (expect 1)\n", newB());
    printf("new'd instance check   : getBNum returns %d (expect 9001)\n", getBNum());
    printf("delete operator check  : deleteB returns %d (expect 0)\n", deleteB());

    // Check that freeing a NULL pointer doesn't fault
    printf("free'ing NULL pointer  : ");
    free(NULL);
    printf("success\n");

    size_t calloc_count = 0x1000;
    size_t calloc_size = 0x40;
    calloc_check(calloc_count, calloc_size);
    calloc_benchmark(calloc_count, calloc_size);

    size_t realloc_size = 0x40000;
    realloc_check(realloc_size);
    realloc_benchmark(realloc_size);

    printf("Malloc stress test starting, will run until interrupted...\n");
    uint32_t allocs = 0;
    while (true) {
        char *str = malloc(33);

        if (str) {
            memcpy(str, test, 33);

            if (strncmp(test, str, 32) != 0) {
                printf("String compare failed at iteration %ld\n", allocs);
                break;
            }

            free(str);
        } else {
            printf("Alloc failed at iteration %ld\n", allocs);
            break;
        }
    }
}

