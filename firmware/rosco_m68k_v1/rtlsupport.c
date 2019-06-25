/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2019 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Stubs for GCC builtins that we don't support (or need).
 * These are here because the 3rd party printf tries to use 
 * them...
 * ------------------------------------------------------------
 */

#include <stdint.h>

unsigned long divmod(unsigned long num, unsigned long den, int mod)
{
  unsigned long bit = 1;
  unsigned long res = 0;

  while (den < num && bit && !(den & (1L<<31))) {
      den <<=1;
      bit <<=1;
  }

  while (bit) {
    if (num >= den) {
      num -= den;
      res |= bit;
    }
    
    bit >>=1;
    den >>=1;
  }

  if (mod) {
    return num;
  } else {
    return res;
  }
}

uint32_t __udivsi3(uint32_t dividend, uint32_t divisor) { return divmod(dividend, divisor, 0); }
uint32_t __umodsi3(uint32_t dividend, uint32_t divisor) { return divmod(dividend, divisor, 1); }
