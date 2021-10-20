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
 * Types and defines for Zmodem implementation
 * ------------------------------------------------------------
 */


#ifndef __ROSCO_M68K_ZTYPES_H
#define __ROSCO_M68K_ZTYPES_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ASCII Control characters
#define XON         0x11
#define XOFF        0x13
#define LF          0x0a
#define CR          0x0d
#define ZPAD        '*'
#define ZDLE        0x18        /* ZDLE and CAN */
#define CAN         0x18        /* are the same */

// ZDLE Escape sequences
#define ZCRCE       'h'
#define ZCRCG       'i'
#define ZCRCQ       'j'
#define ZCRCW       'k'
#define ZRUB0       'l'
#define ZRUB1       'm'

// Header types
#define ZBIN16      'A'
#define ZHEX        'B'
#define ZBIN32      'C'

// Frame types
#define ZRQINIT     0x00
#define ZRINIT      0x01
#define ZSINIT      0x02
#define ZACK        0x03
#define ZFILE       0x04
#define ZSKIP       0x05
#define ZNAK        0x06
#define ZABORT      0x07
#define ZFIN        0x08
#define ZRPOS       0x09
#define ZDATA       0x0a
#define ZEOF        0x0b
#define ZERR        0x0c
#define ZCRC        0x0d
#define ZCHALLENGE  0x0e
#define ZCOMPL      0x0f
#define ZCAN        0x10
#define ZFREECOUNT  0x11
#define ZCOMMAND    0x12
#define ZSTDERR     0x13

// Capabilities for ZRINIT
#define CANFDX      0x01                /* Rx can send and receive true FDX                 */
#define CANOVIO     0x02                /* Rx can receive data during disk I/O              */
#define CANBRK      0x04                /* Rx can send a break signal                       */
#define CANCRY      0x08                /* Receiver can decrypt                             */
#define CANLZW      0x10                /* Receiver can uncompress                          */
#define CANFC32     0x20                /* Receiver can use 32 bit Frame Check              */
#define ESCCTL      0x40                /* Receiver expects ctl chars to be escaped         */
#define ESC8        0x80                /* Receiver expects 8th bit to be escaped           */

// ZFILE conversion options (F0)
#define ZCBIN       0x01                /* Binary transfer - inhibit conversion             */
#define ZCNL        0x02                /* Convert NL to local end of line convention       */
#define ZCRESUM     0x03                /* Resume interrupted file transfer                 */

// ZRESULT Masks
#define VALUE_MASK        0x00ff        /* Mask used to extract value from ZRESULT          */
#define ERROR_MASK        0xf000        /* Mask used to determine if result is an error     */

// ZRESULT codes - Non-errors
#define OK                0x0100        /* Generic return code for "all is well"            */
#define FIN               0x0200        /* OR with < 0xff to indicate a return condition    */
#define GOT_CRCE          (FIN | ZCRCE) /* CRC follows, end of frame, header is next        */
#define GOT_CRCG          (FIN | ZCRCG) /* CRC follows, frame continues (non-stop)          */
#define GOT_CRCQ          (FIN | ZCRCQ) /* CRC follows, frame continues, ZACK expected      */
#define GOT_CRCW          (FIN | ZCRCW) /* CRC follows, end of frame, ZACK expected         */

// ZRESULT codes - Errors
#define BAD_DIGIT         0x1000        /* Bad digit when converting from hex               */
#define CLOSED            0x2000        /* Got EOF when reading from stream                 */
#define BAD_HEADER_TYPE   0x3000        /* Bad header type in stream (probably noise)       */
#define BAD_FRAME_TYPE    0x4000        /* Bad frame type in stream (probably noise)        */
#define CORRUPTED         0x5000        /* Corruption detected in header (probably noise)   */
#define BAD_CRC           0x6000        /* Header did not match CRC (probably noise)        */
#define OUT_OF_RANGE      0x7000        /* Conversion attempted for out-of-range number     */
#define OUT_OF_SPACE      0x8000        /* Supplied buffer is not big enough                */
#define CANCELLED         0x9000        /* 5x CAN received                                  */
#define BAD_ESCAPE        0xa000        /* Bad escape sequence                              */
#define UNSUPPORTED       0xf000        /* Attempted to use an unsupported protocol feature */

#define ERROR_CODE(x)     (x & ERROR_MASK)
#define IS_ERROR(x)       ((bool)(ERROR_CODE((x)) != 0))
#define IS_FIN(x)         ((bool)((x & FIN) == FIN))
#define ZVALUE(x)         ((uint8_t)(x & 0xff))

// Nybble to byte vice-versa
#define NTOB(n1, n2)      (n1 << 4 | n2)        /* 2 nybbles    -> byte                     */
#define BMSN(b)           ((b & 0xf0) >> 4)     /* byte         -> most-significant nybble  */
#define BLSN(b)           (b & 0x0f)            /* byte         -> least-significant nybble */

// Byte to word / vice-versa
#define BTOW(b1, b2)      (b1 << 8 | b2)        /* 2 bytes      -> word                     */
#define WMSB(w)           ((w & 0xff00) >> 8)   /* word         -> most-significant byte    */
#define WLSB(w)           (w & 0x00ff)          /* word         -> least-significant byte   */

// Byte to dword / vice versa
#define BTODW(b1, b2, b3, b4)   (b4 << 24 | b3 << 16 | b2 << 8 | b1)    /* 4 bytes -> dword */
#define DWB1(l)                 (l & 0x000000ff)                        /* MSB              */
#define DWB2(l)                 ((l & 0x0000ff00) >> 8)                 /* 2rd-MSB          */
#define DWB3(l)                 ((l & 0x00ff0000) >> 16)                /* 3nd-MSB          */
#define DWB4(l)                 ((l & 0xff000000) >> 24)                /* LSB              */

// CRC manipulation
#define CRC               BTOW                  /* Convert two-bytes to 16-bit CRC          */
#define CRC_MSB           WMSB                  /* Get most-significant byte of 16-bit CRC  */
#define CRC_LSB           WLSB                  /* Get least-significant byte of 16-bit CRC */

// CRC32 manipulation
#define CRC32             BTODW                 /* Convert four bytes to 32-bit CRC         */
#define CRC32_B1          DWB1                  /* Most-significant byte of CRC32           */
#define CRC32_B2          DWB2                  /* Second-most-significant byte of CRC32    */
#define CRC32_B3          DWB3                  /* Third-most-significant byte of CRC32     */
#define CRC32_B4          DWB4                  /* Least-significant byte of CRC32          */

// Various sizes
#define ZHDR_SIZE         0x09                  /* Size of ZHDR (excluding padding)         */
#define HEX_HDR_STR_LEN   0x11                  /* Total size of a ZHDR encoded as hex      */

/*
 * The ZRESULT type is the general return type for functions in this library.
 *
 */
typedef uint16_t ZRESULT;

typedef struct {
  uint8_t   f3;
  uint8_t   f2;
  uint8_t   f1;
  uint8_t   f0;
} ZFLAGS;

typedef struct {
  uint8_t   p0;
  uint8_t   p1;
  uint8_t   p2;
  uint8_t   p3;
} ZPOS;

typedef struct {
  uint8_t   type;
  union {
    ZFLAGS    flags;
    ZPOS      position;
  };
  uint8_t   crc1;         /* keep these byte-sized to avoid alignment */
  uint8_t   crc2;         /* issues with 16-bit reads on m68k         */
  uint8_t   crc3;
  uint8_t   crc4;
  uint8_t   PADDING;
} ZHDR;

#ifdef ZDEBUG
#define DEBUGF(...)       printf(__VA_ARGS__)
#else
#define DEBUGF(...)
#endif

#ifdef ZTRACE
#define TRACEF(...)       printf(__VA_ARGS__)
#else
#define TRACEF(...)
#endif

#ifdef __cplusplus
}
#endif

#endif /* __ROSCO_M68K_ZTYPES_H */
