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
 * Generic serial routines for Zmodem
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_ZSERIAL_H
#define __ROSCO_M68K_ZSERIAL_H

#include <stdbool.h>
#include <stdint.h>
#include "ztypes.h"

#ifdef __cplusplus
extern "C" {
#endif

#define NONCONTROL(c)    ((bool)((uint8_t)(c & 0xe0)))

/*
 * The lib doesn't implement these - they need to be provided.
 */
ZRESULT zm_recv();
ZRESULT zm_send(uint8_t chr);

/*
 * Receive CR/LF (with CR being optional).
 */
ZRESULT zm_read_crlf();

/*
 * Read two ASCII characters and convert them from hex.
 */
ZRESULT zm_read_hex_byte();

/*
 * Read character, taking care of ZMODEM Data Link Escapes (ZDLE)
 * and swallowing XON/XOFF.
 */
ZRESULT zm_read_escaped();

/*
 * buf must be one character longer than the string...
 * Trashes buf, for obvious reasons.
 */
ZRESULT zm_await(char *str, char *buf, int buf_size);
ZRESULT zm_await_zdle();
ZRESULT zm_await_header(ZHDR *hdr);

ZRESULT zm_read_hex_header(ZHDR *hdr);
ZRESULT zm_read_binary16_header(ZHDR *hdr);
ZRESULT zm_read_binary32_header(ZHDR *hdr);


/*
 * len specifies the maximum length to read on entry,
 * and contains actual length on return.
 */
ZRESULT zm_read_data_block(uint8_t *buf, uint16_t *len);

/*
 * Send a null-terminated string.
 */
ZRESULT zm_send_sz(uint8_t *data);

/*
 * Send the given header as hex, with ZPAD/ZDLE preamble.
 */
ZRESULT zm_send_hex_hdr(ZHDR *hdr);

/*
 * Convenience function to build and send a position header as hex.
 */
ZRESULT zm_send_pos_hdr(uint8_t type, uint32_t pos);

/*
 * Convenience function to build and send a flags header as hex.
 */
ZRESULT zm_send_flags_hdr(uint8_t type, uint8_t f0, uint8_t f1, uint8_t f2, uint8_t f3);

#ifdef __cplusplus
}
#endif

#endif /* __ROSCO_M68K_ZSERIAL_H */
