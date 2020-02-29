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
 * This is the entry point for the Kernel.
 * ------------------------------------------------------------
 */

#include <stddef.h>
#include <stdint.h>
#include <stdnoreturn.h>
#include <stdbool.h>
#include "machine.h"
#include "system.h"
#include "zmodem.h"

#define ZMODEM_LOAD_ADDRESS      0x3000     /* Load code at 12k mark */

// Linker defines
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end;

static SystemDataBlock * const sdb = (SystemDataBlock * const)0x400;
static volatile uint8_t * const mfp_gpdr = (uint8_t * const)MFP_GPDR;

extern void ENABLE_RECV();
extern void ENABLE_XMIT();
extern void SENDCHAR(uint8_t chr);
extern uint8_t RECVCHAR();

typedef void (*LoadFunc)(SystemDataBlock * const);

static char* msg = (char*)ZMODEM_LOAD_ADDRESS;
//static LoadFunc loadfunc = (LoadFunc)ZMODEM_LOAD_ADDRESS;

ZRESULT receive_kernel();

void kinit() {
  // copy .data
  for (uint32_t *dst = &_data_start, *src = &_code_end; dst < &_data_end; *dst = *src, dst++, src++);

  // zero .bss
  for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);
}

noreturn void kmain() {
  *mfp_gpdr |= 0x80;

  if (sdb->magic != 0xB105D47A) {
    EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: SDB Magic mismatch; SDB is trashed. Halting.\r\n");
    HALT();
  }

  // Start the timer tick
  EARLY_PRINT_C("Software initialisation \x1b[1;32mcomplete\x1b[0m; Starting system tick...\r\n");
  START_HEART();

  EARLY_PRINT_C("Initialisation complete; Entering echo loop...\r\n");

  ENABLE_XMIT();
  ENABLE_RECV();

  msg[0] = 0;

  ZRESULT result;
  while ((result = receive_kernel()) != OK) {
    EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Receive failed; Ready for retry...\r\n");
  }

  EARLY_PRINT_C("Returned OK\n");

  EARLY_PRINT_C(msg);

//  EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b: Should not return here; Halting\r\n");

  while (true) {
    //HALT();
  }
}

// Spec says a data packet is max 1024 bytes, but add some headroom...
#define DATA_BUF_LEN    2048

static ZHDR hdr_zrinit = {
  .type = ZRINIT,
  .flags = {
      .f0 = CANOVIO | CANFC32,
      .f1 = 0
  },
  .position = {
      .p0 = 0x00,
      .p1 = 0x00
  }
};

static ZHDR hdr_znak = {
    .type = ZNAK,
    .flags = {
        .f0 = 0,
        .f1 = 0,
        .f2 = 0,
        .f3 = 0
    }
};

static ZHDR hdr_zrpos = {
    .type = ZRPOS,
    .position = {
        .p0 = 0,
        .p1 = 0,
        .p2 = 0,
        .p3 = 0
    }
};

static ZHDR hdr_zabort = {
    .type = ZABORT,
    .position = {
        .p0 = 0,
        .p1 = 0,
        .p2 = 0,
        .p3 = 0
    }
};

static ZHDR hdr_zack = {
    .type = ZACK,
    .position = {
        .p0 = 0,
        .p1 = 0,
        .p2 = 0,
        .p3 = 0
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

static uint8_t zrinit_buf[HEX_HDR_STR_LEN + 1];
static uint8_t znak_buf[HEX_HDR_STR_LEN + 1];
static uint8_t zrpos_buf[HEX_HDR_STR_LEN + 1];
static uint8_t zabort_buf[HEX_HDR_STR_LEN + 1];
static uint8_t zack_buf[HEX_HDR_STR_LEN + 1];
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

ZRESULT receive_kernel() {
  uint8_t rzr_buf[4];
  uint8_t *data_buf = (uint8_t*)ZMODEM_LOAD_ADDRESS;
  uint16_t count;
  uint32_t received_data_size = 0;
  ZHDR hdr;

  // Set up static header buffers for later use...
  if (IS_ERROR(init_hdr_buf(&hdr_zrinit, zrinit_buf))) {
    return OUT_OF_SPACE;
  }
  if (IS_ERROR(init_hdr_buf(&hdr_znak, znak_buf))) {
    return OUT_OF_SPACE;
  }
  if (IS_ERROR(init_hdr_buf(&hdr_zrpos, zrpos_buf))) {
    return OUT_OF_SPACE;
  }
  if (IS_ERROR(init_hdr_buf(&hdr_zabort, zabort_buf))) {
    return OUT_OF_SPACE;
  }
  if (IS_ERROR(init_hdr_buf(&hdr_zack, zack_buf))) {
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
            
            result = zm_send_hdr(&hdr_zrpos);

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

