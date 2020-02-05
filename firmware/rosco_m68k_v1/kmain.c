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
#include "rosco_m68k.h"
#include "machine.h"
#include "system.h"
#include "servers/serial.h"
#include "3rdparty/printf.h"
#include "zmodem.h"

#define ZMODEM_LOAD_ADDRESS      0x1000;     /* Load code at 4k mark */

typedef void (*LoadFunc)(KernelApi*);

// Linker defines
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end;

extern void __initializeKernelApiPtr();
extern void __initializeSerialServer();
extern void __initializePrintf(Serial *serial);

static SystemDataBlock * const sdb = (SystemDataBlock * const)0x400;

static Serial *serial;

ZRESULT receive_kernel();

void kinit() {
  // copy .data
  for (uint32_t *dst = &_data_start, *src = &_code_end; dst < &_data_end; *dst = *src, dst++, src++);

  // zero .bss
  for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst = 0, dst++);
}

noreturn void kmain() {
  if (sdb->magic != 0xB105D47A) {
    EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: SDB Magic mismatch; SDB is trashed. Halting.\r\n");
    HALT();
  }

  // Set up the rest of the System Data Block
  EARLY_PRINT_C("Initialising System Data Block...\r\n");
  // TODO
  
  // Set up the KernelAPI pointer (at 0x04)
  EARLY_PRINT_C("Initialising kernel API...\r\n");
  __initializeKernelApiPtr();

  // Have the serial server initalize itself
  EARLY_PRINT_C("Initialising serial server...\r\n");
  __initializeSerialServer();

  serial = GetKernelApi()->FindLibrary("serial0", ROSCOM68K_SERIAL_MAGIC);

  if (serial == NULL) {
    EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Serial driver failed to initialise. Halting.\r\n");
    HALT();
  }

  // Initialize printf with the new serial
  __initializePrintf(serial);

  // Start the timer tick
  printf("Software initialisation \x1b[1;32mcomplete\x1b[0m; Starting system tick...\r\n");
  START_HEART();

  printf("Initialisation complete; Ready to receive kernel via serial link\r\n");

  ZRESULT result;
  while ((result = receive_kernel()) != OK) {
    printf("\x1b[1;31mSEVERE\x1b[0m: Receive failed: %0x%04x; Ready for retry...\r\n", ERROR_CODE(result));
  }

  printf("\x1b[1;31mSEVERE\x1b: Should not return here; Halting\r\n");

  while (true) {
    HALT();
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
  serial->SendChar(c);
  return OK;
}

ZRESULT zm_recv() {
  return serial->BlockingReadChar();
}


ZRESULT receive_kernel() {
  uint8_t rzr_buf[4];
  uint8_t *data_buf = (uint8_t*)ZMODEM_LOAD_ADDRESS;
  LoadFunc loadfunc = (LoadFunc)ZMODEM_LOAD_ADDRESS;
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
      case OK:
        switch (hdr.type) {
        case ZRQINIT:
        case ZEOF:
          result = zm_send_hex_hdr(zrinit_buf);

          if (result != OK) {
            return result;
          }

          continue;

        case ZFIN:
          result = zm_send_hex_hdr(zfin_buf);

          // Jump to received code
          loadfunc(GetKernelApi());

        case ZFILE:
          // TODO Process hdr.flags.f0 to determine if we support the transfer options?
          //      Currently, just ignore and always use binary...
          count = DATA_BUF_LEN;
          result = zm_read_data_block(data_buf, &count);

          if (!IS_ERROR(result)) {

            // TODO any buffer init or whatever...

            result = zm_send_hex_hdr(zrpos_buf);

            if (result != OK) {
              return result;
            }
          }

          // TODO care about XON that will follow?

          continue;

        case ZDATA:
          while (true) {
            count = DATA_BUF_LEN;
            result = zm_read_data_block(data_buf, &count);

            // count is one more than the actual data length to account for frameend.
            received_data_size += (count - 1);

            if (!IS_ERROR(result)) {
              // Point data_buf to next free section of memory.
              data_buf += received_data_size;

              if (result == GOT_CRCE) {
                // End of frame, header follows, no ZACK expected.
                break;
              } else if (result == GOT_CRCG) {
                // Frame continues, non-stop (another data packet follows)
                continue;
              } else if (result == GOT_CRCQ) {
                // Frame continues, ACK required
                result = zm_send_hex_hdr(zack_buf);
                
                if (result != OK) {
                  return result;
                }

                continue;
              } else if (result == GOT_CRCW) {
                // End of frame, header follows, ZACK expected.

                result = zm_send_hex_hdr(zack_buf);

                if (result != OK) {
                  return result;
                }

                break;
              }

            } else {
              // Error receiving block
              result = zm_send_hex_hdr(znak_buf);

              if (result != OK) {
                return result;
              }
            }
          }

          continue;

        default:
          // UNKNOWN HEADER - Just ignore
          continue;
        }

        break;
      case BAD_CRC:
        result = zm_send_hex_hdr(znak_buf);

        if (result != OK) {
          return result;
        }

        continue;
      default:
        // Other error result - probably noise when receiving
        result = zm_send_hex_hdr(znak_buf);

        if (result != OK) {
          return result;
        }

        continue;
      }
    }
  }

  return OK;
}

