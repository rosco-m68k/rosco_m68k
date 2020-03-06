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
 * Basic implementations for GCC builtins and RTL routines that we
 * need for various things.
 * ------------------------------------------------------------
 */

#include <stdint.h>

void *memset(void *str, int c, long unsigned int n) {
  // totally naive implementation, will do for now...
  uint8_t *buf = (uint8_t*)str;

  for (uint8_t *end = buf + n; buf < end; *buf++ = c);

  return str;
}

int strcmp (const char* str1, const char* str2) {
  register char c1, c2;

  while ((c1 = *str1++)) {
    if (!(c2 = *str2++)) {
      return 1;
    } else if (c1 != c2) {
      return c1 - c2;
    }
  }

  if (*str2) {
    return -1;
  } else {
    return 0;
  }
}

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
