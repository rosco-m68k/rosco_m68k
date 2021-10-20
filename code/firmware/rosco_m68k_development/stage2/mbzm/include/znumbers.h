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
 * Numeric-related routines for Zmodem implementation.
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_ZNUMBERS_H
#define __ROSCO_M68K_ZNUMBERS_H

#include <stdint.h>
#include "ztypes.h"

#ifdef __cplusplus
extern "C" {
#endif

ZRESULT zm_hex_to_nybble(char c1);

ZRESULT zm_nybble_to_hex(uint8_t nybble);

/*
 * *buf MUST have space for exactly two characters!
 *
 * Returns OK on success, or an error code.
 * If an error occues, the buffer will be unchanged.
 */
ZRESULT zm_byte_to_hex(uint8_t byte, uint8_t *buf);

ZRESULT zm_hex_to_byte(unsigned char c1, unsigned char c2);

#ifdef __cplusplus
}
#endif

#endif /* __ROSCO_M68K_ZNUMBERS_H */

