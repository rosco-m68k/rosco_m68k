/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v1
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Routines for working with Zmodem headers
 * ------------------------------------------------------------
 */

#ifdef ZDEBUG
#include <stdio.h>
#endif

#include "zheaders.h"
#include "znumbers.h"
#include "crc16.h"
#include "crc32.h"

void zm_calc_hdr_crc(ZHDR *hdr) {
  uint16_t crc = ucrc16(hdr->type, CRC_START_XMODEM);
  crc = ucrc16(hdr->flags.f3, crc);
  crc = ucrc16(hdr->flags.f2, crc);
  crc = ucrc16(hdr->flags.f1, crc);
  crc = ucrc16(hdr->flags.f0, crc);

  hdr->crc1 = CRC_MSB(crc);
  hdr->crc2 = CRC_LSB(crc);
}

uint16_t zm_calc_data_crc(uint8_t *buf, uint16_t len) {
  uint16_t crc = CRC_START_XMODEM;

  for (int i = 0; i < len; i++) {
    crc = ucrc16(buf[i], crc);
  }

  return crc;
}

uint32_t zm_calc_data_crc32(uint8_t *buf, uint16_t len) {
  return crc32((char*)buf, len);
}

ZRESULT zm_to_hex_header(ZHDR *hdr, uint8_t *buf, int max_len) {
  if (max_len < HEX_HDR_STR_LEN) {
    return OUT_OF_SPACE;
  } else {
    *buf++ = 'B';                      // 01

    zm_byte_to_hex(hdr->type, buf);    // 03
    buf += 2;
    zm_byte_to_hex(hdr->flags.f3, buf);// 05
    buf += 2;
    zm_byte_to_hex(hdr->flags.f2, buf);// 07
    buf += 2;
    zm_byte_to_hex(hdr->flags.f1, buf);// 09
    buf += 2;
    zm_byte_to_hex(hdr->flags.f0, buf);// 0b
    buf += 2;
    zm_byte_to_hex(hdr->crc1, buf);    // 0d
    buf += 2;
    zm_byte_to_hex(hdr->crc2, buf);    // 0f
    buf += 2;
    *buf++ = CR;                       // 10
    *buf++ = LF | 0x80;                // 11

    return HEX_HDR_STR_LEN;
  }
}

ZRESULT zm_check_header_crc16(ZHDR *hdr, uint16_t crc) {
  if (CRC(hdr->crc1, hdr->crc2)  == crc) {
    return OK;
  } else {
    return BAD_CRC;
  }
}

ZRESULT zm_check_header_crc32(ZHDR *hdr, uint32_t crc) {
  if (CRC32(hdr->crc1, hdr->crc2, hdr->crc3, hdr->crc4)  == crc) {
    return OK;
  } else {
    return BAD_CRC;
  }
}


