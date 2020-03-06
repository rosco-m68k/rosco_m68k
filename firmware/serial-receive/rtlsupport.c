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
 * Basic, naive implementations for RTL routines that we
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

