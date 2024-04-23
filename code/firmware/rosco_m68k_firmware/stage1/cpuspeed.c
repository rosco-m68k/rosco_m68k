/*
 * vim: set et ts=2 sw=2
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|                       
 * ------------------------------------------------------------
 * Copyright (c) 2020 Xark
 * MIT License
 * ------------------------------------------------------------
 */

#include <machine.h>

#define _TIMER_100HZ  0x40c

uint32_t cpuspeed(uint8_t model) {
    uint32_t count;
    uint32_t tv;
    uint8_t mult;

    if (model == 0 || model == 1) {
      mult = 26;
    } else if (model == 2) {
      mult = 30;
    } else if (model == 3) {
      mult = 32;
    } else {
      mult = 0;
    }

    __asm__ __volatile__(
        "   moveq.l #0,%[count]\n"
        "   move.w  0x40e.w,%[tv]\n"
        "0: cmp.w   0x40e.w,%[tv]\n"
        "   beq.s   0b\n"
        "   move.w  0x40e.w,%[tv]\n"
        "1: addq.w  #1,%[count]\n"
        "   cmp.w   0x40e.w,%[tv]\n"
        "   beq.s   1b\n"
        : [count] "=d"(count), [tv] "=&d"(tv)
        :
        :"d0");

    return ((count * mult) + 500);
}

unsigned int __mulsi3(unsigned int a, unsigned int b) {
    unsigned int r = 0;

    while (a) {
        if (a & 1) {
            r += b;
        }

        a >>= 1;
        b <<= 1;
    }

    return r;
}
