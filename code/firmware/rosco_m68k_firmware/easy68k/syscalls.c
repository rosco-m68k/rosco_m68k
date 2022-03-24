/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Easy68K-compatible System calls - C parts (Not reentrant!)
 * ------------------------------------------------------------
 */
#include <stdint.h>
#include <stdbool.h>
#include "machine.h"

#define BUF_LEN 78
#define BUF_MAX BUF_LEN - 2

extern void FW_PRINT_C(char *str);

static uint8_t buf[BUF_LEN];

extern uint8_t digit(unsigned char digit);

static unsigned char* print_signed_impl(int32_t value, unsigned char *bp) {
  bool neg = false;

  if (value & 1 << 31) {
    value = (~value) + 1;
    neg = true;
  }

  while (value > 0) {
    *bp-- = digit(value % 10);
    value /= 10;
  }

  if (neg) {
    *bp-- = '-';
  }

  *bp = 0;

  return bp + 1;
}

void print_signed(int32_t value) {
  unsigned char *ptr = print_signed_impl(value, &buf[BUF_MAX]);
  FW_PRINT_C((char*)ptr);
}

void print_signed_width(int32_t value, uint8_t width) {
  if (width == 0 || width >= BUF_MAX) {
    return;
  }

  unsigned char *end = &buf[BUF_MAX];
  unsigned char *start = print_signed_impl(value, end);

  uint8_t len = (uint32_t)end - (uint32_t)start + 1;

  if (len > width) {
    start += (len - width);
    len = (uint32_t)end - (uint32_t)start + 1;
  }

  while (len < width) {
    *--start = ' ';
    len++;
  }

  FW_PRINT_C((char*)start);
}

uint8_t digit(unsigned char digit) {
  if (digit < 10) {
    return (char)(digit + '0');
  } else {
    return (char)(digit - 10 + 'A');
  }
}

void print_unsigned(uint32_t num, uint8_t base) {
  if (base < 2 || base > 36) {
    return;
  }

  unsigned char bp = BUF_MAX;

  if (num == 0) {
    buf[bp--] = '0';
  } else {
    while (num > 0) {
      buf[bp--] = digit(num % base);
      num /= base;
    }
  }

  FW_PRINT_C((char*)&buf[bp+1]);
}
