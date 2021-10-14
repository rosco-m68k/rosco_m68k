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

static const char *test = "TESTING!TESTING!TESTING!TESTING!";

extern int newB();
extern int getBNum();
extern int deleteB();

void kmain() {
    printf("C++ new/delete test starting\n");
    
    printf("new operator check     : newB returns    %d (expect 1)\n", newB());
    printf("new'd instance check   : getBNum returns %d (expect 9001)\n", getBNum());
    printf("delete operator check  : deleteB returns %d (expect 0)\n", deleteB());

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

