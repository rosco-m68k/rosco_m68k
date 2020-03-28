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
 * Glue code for the ZMODEM kernel loader
 * ------------------------------------------------------------
 */

#include "serial.h"
#include "zmodem.h"

// Spec says a data packet is max 1024 bytes, but add some headroom...
#define DATA_BUF_LEN    1056

static ZHDR hdr_zrinit = {
  .type = ZRINIT,
  .flags = {
      .f0 = CANOVIO /* | CANFC32 // mbzm can't actually FC32 at the moment :D */,
      .f1 = 0
  },
  .position = {
      .p0 = 0x00,
      .p1 = 0x00
  }
};

static ZHDR hdr_zfin = {
    .type = ZFIN,
    .position = {
        .p0 = 0,
        .p1 = 0,
        .p2 = 0,
        .p3 = 0
    }
};

extern uint8_t *kernel_load_ptr;

static uint8_t zrinit_buf[HEX_HDR_STR_LEN + 1];
static uint8_t zfin_buf[HEX_HDR_STR_LEN + 1];

static ZRESULT init_hdr_buf(ZHDR *hdr, uint8_t *buf) {
  buf[HEX_HDR_STR_LEN] = 0;
  zm_calc_hdr_crc(hdr);
  return zm_to_hex_header(hdr, buf, HEX_HDR_STR_LEN);
}

/* Send/Receive impl for mbzm */
ZRESULT zm_send(uint8_t c) {
  SENDCHAR(c);
  return OK;
}

ZRESULT zm_recv() {
  return RECVCHAR();
}

ZRESULT zm_receive_kernel() {
  uint8_t rzr_buf[4];
  uint8_t *data_buf = kernel_load_ptr;
  uint16_t count;
  uint32_t received_data_size = 0;
  ZHDR hdr;

  // Set up static header buffers for later use...
  if (IS_ERROR(init_hdr_buf(&hdr_zrinit, zrinit_buf))) {
    return OUT_OF_SPACE;
  }
  if (IS_ERROR(init_hdr_buf(&hdr_zfin, zfin_buf))) {
    return OUT_OF_SPACE;
  }

  if (zm_await("rz\r", (char*)rzr_buf, 4) == OK) {

    while (true) {
      uint16_t result = zm_await_header(&hdr);

      switch (result) {
      case TIMEOUT:
        zm_resend_last_header();
        continue;

      case OK:
        switch (hdr.type) {
        case ZRQINIT:
        case ZEOF:
          result = zm_send_hdr(&hdr_zrinit);

          if (IS_ERROR(result)) {
            return result;
          }

          continue;

        case ZFIN:
          result = zm_send_hdr(&hdr_zfin);

          // TODO just ignoring 'OO' at end of xfer...

          return OK;

        case ZFILE:
          count = DATA_BUF_LEN;
          result = zm_read_data_block(data_buf, &count);

          if (!IS_ERROR(result) && result == GOT_CRCW) {

            result = zm_send_hdr_pos32(ZRPOS, 0);

            if (IS_ERROR(result)) {
              return result;
            }
          } else {
            zm_send_hdr(&hdr_zrinit);
          }

          // TODO care about XON that will follow?

          continue;

        case ZNAK:
          zm_send_hdr_pos32(ZABORT, 0);
          return CORRUPTED;

        case ZDATA:
          while (true) {
            count = DATA_BUF_LEN;
            result = zm_read_data_block(data_buf, &count);

            if (!IS_ERROR(result)) {

              received_data_size += (count - 1);
              data_buf += (count - 1);

              if (result == GOT_CRCE) {
                // End of frame, header follows, no ZACK expected.
                break;
              } else if (result == GOT_CRCG) {
                // Frame continues, non-stop (another data packet follows)
                continue;
              } else if (result == GOT_CRCQ) {
                // Frame continues, ACK required
                result = zm_send_hdr_pos32(ZACK, received_data_size);

                if(IS_ERROR(result)) {
                  return result;
                }

                continue;

              } else if (result == GOT_CRCW) {
                // End of frame, header follows, ZACK expected.
                result = zm_send_hdr_pos32(ZACK, received_data_size);

                if(IS_ERROR(result)) {
                  return result;
                }

                break;

              }

            } else if (result == CORRUPTED || result == BAD_CRC || result == BAD_ESCAPE) {
              result = zm_send_hdr_pos32(ZRPOS, received_data_size);

              if (IS_ERROR(result)) {
                return result;
              }

              break;

            } else {
              // FATAL
              return result;
            }
          }

          break;

        default:
          // FATAL
          return result;
        }

        break;

      case CANCELLED:
        return CANCELLED;

      default:
        // Just try to send a ZRPOS to attempt recovery...
        result = zm_send_hdr_pos32(ZRPOS, received_data_size);

        if (IS_ERROR(result)) {
          return result;
        }

        continue;
      }
    }
  }

  return OK;
}

/* Called by main */
int receive_kernel() {
    return zm_receive_kernel() == OK ? 1 : 0;
}
