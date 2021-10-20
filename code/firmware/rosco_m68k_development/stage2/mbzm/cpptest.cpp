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
 * This is just here to test the lib can be compiled with C++
 * ------------------------------------------------------------
 */

#include <iostream>

#include "zmodem.h"

extern "C" ZRESULT zm_send(uint8_t) { return OK; }
extern "C" ZRESULT zm_recv() { return CLOSED; }

static ZHDR hdr;
static uint8_t buffer[HEX_HDR_STR_LEN + 1];

static ZRESULT init_hdr_buf(ZHDR *hdr, uint8_t *buf) {
  buf[HEX_HDR_STR_LEN-1] = 0;
  zm_calc_hdr_crc(hdr);
  return zm_to_hex_header(hdr, buf, HEX_HDR_STR_LEN);
}

int main() {
  hdr.type = ZFIN;
  ZRESULT result = init_hdr_buf(&hdr, buffer);

  if (result == HEX_HDR_STR_LEN) {
    std::cout << "Struct initialized: " << buffer << std::endl;
  } else {
    std::cerr << "Something went wrong; " << result << std::endl;
  }
}
