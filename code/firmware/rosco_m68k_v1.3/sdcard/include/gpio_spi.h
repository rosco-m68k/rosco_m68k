/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2020 Xark
 * MIT License
 *
 * Routines for SPI mode 0 (CPOL=0, CPHA=0) implemented in assembly.
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_GPIO_SPI_H
#define _ROSCOM68K_GPIO_SPI_H

#include <machine.h>
#include <gpio.h>

// SPI functions are static, so inlining depends on compiler optimization
// level.  However, you can influence the compiler by defining one of these:
// SPI_FAST   - encourage the compiler to inline functions
// SPI_SMALL  - prevent the compiler from inlining functions
#if !defined(SPI_INLINE)
#if defined(SPI_FAST)
#define SPI_INLINE    inline
#elif defined(SPI_SMALL)
#define SPI_INLINE __attribute__ ((noinline))
#else
#define SPI_INLINE
#endif
#endif

// Default rosco SPI pins
#if !defined(SPI_CS_B)
#define SPI_CS_B      GPIO1_B
#endif
#if !defined(SPI_SCK_B)
#define SPI_SCK_B     GPIO2_B
#endif
#if !defined(SPI_COPI_B)
#define SPI_COPI_B    GPIO3_B
#endif
#if !defined(SPI_CIPO_B)
#define SPI_CIPO_B    GPIO4_B
#endif

// SPI active LEDs - LEDs to set during buffer transfers
// NOTE: Normal rosco_m68k LED blinking overridden during transfers
#if !defined(SPI_LED)
#define SPI_LED     (LED_RED|LED_GREEN)         // LEDs on during block transfer (or 0)
#endif

// calculate bit values for bit positions
#define SPI_CS        (1<<SPI_CS_B)
#define SPI_SCK       (1<<SPI_SCK_B)
#define SPI_COPI      (1<<SPI_COPI_B)
#define SPI_CIPO      (1<<SPI_CIPO_B)

// send one SPI byte, ignore received byte
static SPI_INLINE void spi_send_byte(int byte) __attribute__ ((used));
static SPI_INLINE void spi_send_byte(int byte)
{
  int sck_lo, temp;
  __asm__ __volatile__ (
    "     move.b  (%[gpdr]),%[sck_lo]     \n"   //  8   read current GPDR byte
    "     and.b   %[maskbits],%[sck_lo]   \n"   //  8   mask out SPI bits
    "   .rept   8                         \n"   //      repeat code 8 times for full byte
    "     add.b   %[byte],%[byte]         \n"   //  4   shift send byte MSB into carry
    "     scs     %[temp]                 \n"   // 4/6  set temp to 0 or -1 based on carry
    "     and.b   %[copi],%[temp]         \n"   //  4   mask out all bits except COPI
    "     or.b    %[sck_lo],%[temp]       \n"   //  4   set other GPIO bits
    "     move.b  %[temp],(%[gpdr])       \n"   //  8   output SCK low and COPI value
    "     bset.b  %[sckbit],(%[gpdr])     \n"   //  12  set SCK high
    "   .endr                             \n"   //      end repeat
    "     or.b   %[ledoff],(%[gpdr])      \n"   //  12  set LED off

    : // outputs
      [byte] "+&d" (byte),                      // in/out D-reg
      [sck_lo] "=&d" (sck_lo),                  // temp D-reg
      [temp] "=&d" (temp)                       // temp D-reg
    : // inputs
      [gpdr] "a" (MFP_GPDR),                    // GPDR address A-reg
      [sckbit] "d" (SPI_SCK_B),                 // COPI bit # D-reg
      [copi] "d" (SPI_COPI),                    // COPI value D-reg
      [maskbits] "n" (~(SPI_SCK|SPI_COPI|SPI_LED)), // SPI bit mask value
      [ledoff] "n" (SPI_LED)                    // LED off
    : // clobbers (none)
  );
}

// send "count" SPI bytes (> 0) from data, ignore received bytes
static SPI_INLINE void spi_send_buffer(void* data, int count) __attribute__ ((used));
static SPI_INLINE void spi_send_buffer(void* data, int count)
{
  int byte, sck_lo, temp;
  __asm__ __volatile__ (
    "     move.b  (%[gpdr]),%[sck_lo]     \n"   //  8   read current GPDR byte
    "     and.b   %[maskbits],%[sck_lo]   \n"   //  8   mask out SPI bits
    "     move.b  %[sck_lo],(%[gpdr])     \n"   //  8   set SCK low
    "0:   move.b  (%[data])+,%[byte]      \n"   //  8   load byte from memory
    "   .rept   8                         \n"   //      repeat code 8 times for full byte
    "     add.b   %[byte],%[byte]         \n"   //  4   shift send byte MSB into carry
    "     scs     %[temp]                 \n"   // 4/6  set temp to 0 or -1 based on carry
    "     and.b   %[copi],%[temp]         \n"   //  4   mask out all bits except COPI bit
    "     or.b    %[sck_lo],%[temp]       \n"   //  4   set other GPIO bits
    "     move.b  %[temp],(%[gpdr])       \n"   //  8   output SCK low GPIO value
    "     bset.b  %[sckbit],(%[gpdr])     \n"   //  12  set SCK high
    "   .endr                             \n"   //      end repeat
    "     subq.l  #1,%[count]             \n"   //  4   decrement byte count
    "     bne     0b                      \n"   // 8/10 loop until count bytes read
    "     or.b   %[ledoff],(%[gpdr])      \n"   //  12  set LED off

    : // outputs
      [data] "+&a" (data),                      // in/out A-reg
      [count] "+&d" (count),                    // in/out D-reg
      [byte] "=&d" (byte),                      // temp D-reg
      [sck_lo] "=&d" (sck_lo),                  // temp D-reg
      [temp] "=&d" (temp)                       // temp D-reg
    : // inputs
      [gpdr] "a" (MFP_GPDR),                    // GPDR address A-reg
      [sckbit] "d" (SPI_SCK_B),                 // COPI bit # D-reg
      [copi] "d" (SPI_COPI),                    // COPI value D-reg
      [maskbits] "n" (~(SPI_SCK|SPI_COPI|SPI_LED)), // SPI bit mask value
      [ledoff] "n" (SPI_LED)                    // LED off value
    : // clobbers (none)
  );
}

// send one SPI byte and receive one SPI byte
static SPI_INLINE int spi_exchange_byte(int byte) __attribute__ ((used));
static SPI_INLINE int spi_exchange_byte(int byte)
{
  int sck_lo, temp;
  __asm__ __volatile__ (
    "     move.b  (%[gpdr]),%[sck_lo]     \n"   //  8   read current GPDR byte
    "     and.b   %[maskbits],%[sck_lo]   \n"   //  8   mask out SPI bits
    "   .rept   8                         \n"   //      repeat code 8 times for full byte
    "     move.b  %[sck_lo],(%[gpdr])     \n"   //  8   set SCK low
    "     add.b   %[byte],%[byte]         \n"   //  4   shift send byte MSB into carry
    "     bcc.b   0f                      \n"   // 8/10 set temp to 0 or -1 based on carry
    "     bset.b  %[copibit],(%[gpdr])    \n"   //  12  set COPI bit
    "0:   bset.b  %[sckbit],(%[gpdr])     \n"   //  12  set SCK bit high
    "     btst.b  %[cipobit],(%[gpdr])    \n"   //  8   test CIPO bit
    "     sne     %[temp]                 \n"   // 4/6  set temp to 0 or -1 based on CIPO
    "     sub.b   %[temp],%[byte]         \n"   //  4   add 0 or 1 to receive byte
    "   .endr                             \n"   //      end repeat
    "     or.b   %[ledoff],(%[gpdr])      \n"   //  12  set LED off

    : // outputs
      [byte] "+&d" (byte),                      // in/out D-reg
      [sck_lo] "=&d" (sck_lo),                  // temp D-reg
      [temp] "=&d" (temp)                       // temp D-reg
    : // inputs
      [gpdr] "a" (MFP_GPDR),                    // GPDR address A-reg
      [sckbit] "d" (SPI_SCK_B),                 // SCK bit # D-reg
      [copibit] "d" (SPI_COPI_B),               // COPI bit # D-reg
      [cipobit] "d" (SPI_CIPO_B),               // CIPO bit # D-reg
      [maskbits] "n" (~(SPI_SCK|SPI_COPI|SPI_LED)), // SPI bit mask value
      [ledoff] "n" (SPI_LED)                    // LED off value
    : // clobbers (none)
  );

  return byte;
}

// send "count" SPI bytes (> 0) from data, and store "count" received bytes into data
static SPI_INLINE void spi_exchange_buffer(void *data, int count) __attribute__ ((used));
static SPI_INLINE void spi_exchange_buffer(void *data, int count)
{
  int byte, sck_lo, temp;
  __asm__ __volatile__ (
    "     move.b  (%[gpdr]),%[sck_lo]     \n"   //  8   read current GPDR byte
    "     and.b   %[maskbits],%[sck_lo]   \n"   //  8   mask out SPI bits
    "     move.b  %[sck_lo],(%[gpdr])     \n"   //  8   set SCK low
    "0:   move.b  (%[data]),%[byte]       \n"   //  8   load send byte from memory
    "   .rept   8                         \n"   //      repeat code 8 times for full byte
    "     add.b   %[byte],%[byte]         \n"   //  4   shift send byte MSB into carry
    "     scs     %[temp]                 \n"   //  4/6 set temp to 0 or -1 based on carry
    "     and.b   %[copi],%[temp]         \n"   //  4   mask out all bits except COPI bit
    "     or.b    %[sck_lo],%[temp]       \n"   //  4   set other GPIO bits
    "     move.b  %[temp],(%[gpdr])       \n"   //  8   output SCK low GPIO value
    "     bset.b  %[sckbit],(%[gpdr])     \n"   //  12  set SCK high
    "     btst.b  %[cipobit],(%[gpdr])    \n"   //  8   test CIPO input bit
    "     sne     %[temp]                 \n"   // 4/6  set temp to 0 or -1 based on CIPO
    "     sub.b   %[temp],%[byte]         \n"   //  4   add 0 or 1 to receive byte
    "   .endr                             \n"   //      end repeat
    "     move.b  %[byte],(%[data])+      \n"   //  8   store receieve byte to memory
    "     subq.l  #1,%[count]             \n"   //  4   decrement byte count
    "     bne     0b                      \n"   // 8/10 loop until count bytes read
    "     or.b   %[ledoff],(%[gpdr])      \n"   // 12   set LED off

    : // outputs
      [data] "+&a" (data),                      // in/out A reg
      [count] "+&d" (count),                    // in/out D reg
      [byte] "=&d" (byte),                      // temp D reg
      [sck_lo] "=&d" (sck_lo),                  // temp D reg
      [temp] "=&d" (temp)                       // temp D reg
    : // inputs
      [gpdr] "a" (MFP_GPDR),                    // GPDR address A reg
      [sckbit] "d" (SPI_SCK_B),                 // SCK bit # D-reg
      [copi] "d" (SPI_COPI),                    // COPI value D-reg
      [cipobit] "d" (SPI_CIPO_B),               // CIPO bit # D-reg
      [maskbits] "n" (~(SPI_SCK|SPI_COPI|SPI_LED)), // SPI bit mask value
      [ledoff] "n" (SPI_LED)                    // LED off value
    : // clobbers (none)
  );
}

// reads one SPI byte, sends one dummy 0xff byte, 
static SPI_INLINE int spi_read_byte(void) __attribute__ ((used));
static SPI_INLINE int spi_read_byte(void)
{
  int byte = 0, sck_lo, sck_hi, temp;
  __asm__ __volatile__ (
    "     move.b  (%[gpdr]),%[sck_lo]     \n"   //  8   read current GPDR byte
    "     and.b   %[maskbits],%[sck_lo]   \n"   //  8   mask out SPI bits
    "     move.b  %[sck_lo],%[sck_hi]     \n"   //  8   copy for sck_hi
    "     or.b    %[sck],%[sck_hi]        \n"   //  8   set SCK bit
    "0:   move.b  %[sck_lo],(%[gpdr])     \n"   //  8   clear SCK
    "     move.b  %[sck_hi],(%[gpdr])     \n"   //  8   set SCK high
    "     btst.b  %[cipobit],(%[gpdr])    \n"   //  8   test CIPO bit
    "     sne     %[temp]                 \n"   //  4/6 set temp to 0 or -1 based on CIPO
    "     sub.b   %[temp],%[byte]         \n"   //  4   add 0 or 1 to output byte
    "   .rept   7                         \n"   //      repeat code 7 times for full byte
    "     move.b  %[sck_lo],(%[gpdr])     \n"   //  8   clear SCK
    "     add.b   %[byte],%[byte]         \n"   //  4   shift receive byte
    "     move.b  %[sck_hi],(%[gpdr])     \n"   //  8   set SCK high
    "     btst.b  %[cipobit],(%[gpdr])    \n"   //  8   test CIPO bit
    "     sne     %[temp]                 \n"   //  4/6 set temp to 0 or -1 based on CIPO
    "     sub.b   %[temp],%[byte]         \n"   //  4   add 0 or 1 to output byte
    "   .endr                             \n"   //      end repeat
    "     or.b   %[ledoff],(%[gpdr])      \n"   // 12   set LED off
    : // outputs
      [byte] "+&d" (byte),                      // temp D-reg
      [sck_lo] "=&d" (sck_lo),                  // temp D-reg
      [sck_hi] "=&d" (sck_hi),                  // temp D-reg
      [temp] "=&d" (temp)                       // temp D-reg
    : // inputs
      [gpdr] "a" (MFP_GPDR),                    // GPDR address A-reg
      [cipobit] "d" (SPI_CIPO_B),               // CIPO bit # D-reg
      [sck] "n" (SPI_SCK),                      // SCK value
      [maskbits] "n" (~(SPI_SCK|SPI_LED)),      // SPI bit mask value
      [ledoff] "n" (SPI_LED)                    // LED off value
    : // clobbers (none)
  );

  return byte;
}

// reads "count" SPI bytes (> 0) into data, sends "count" dummy 0xff bytes
static SPI_INLINE void spi_read_buffer(void *data, int count) __attribute__ ((used));
static SPI_INLINE void spi_read_buffer(void *data, int count)
{
  int byte, sck_lo, sck_hi, temp;
  __asm__ __volatile__ (
    "     move.b  (%[gpdr]),%[sck_lo]     \n"   //  8   read current GPDR byte
    "     and.b   %[maskbits],%[sck_lo]   \n"   //  8   mask out SPI bits
    "     move.b  %[sck_lo],%[sck_hi]     \n"   //  8   copy for sck_hi
    "     or.b    %[sck],%[sck_hi]        \n"   //  8   set SCK bit
    "0:                                   \n"
    " .rept   8                           \n"   //      repeat bit code 8 times for byte
    "     move.b  %[sck_lo],(%[gpdr])     \n"   //  8   clear SCK
    "     add.b   %[byte],%[byte]         \n"   //  4   shift byte/clear low bit
    "     move.b  %[sck_hi],(%[gpdr])     \n"   //  8   set SCK high
    "     btst.b  %[cipobit],(%[gpdr])    \n"   //  8   test CIPO bit
    "     sne     %[temp]                 \n"   // 4/6  set temp to 0 or -1 for this bit
    "     sub.b   %[temp],%[byte]         \n"   //  4   sub 0 or -1 from previous bit test
    "   .endr                             \n"   //      end repeat
    "     move.b  %[byte],(%[data])+      \n"   //  8   save received byte
    "     subq.l  #1,%[count]             \n"   //  4   decrement byte count
    "     bne     0b                      \n"   // 8/10 loop until count bytes read
    "     or.b   %[ledoff],(%[gpdr])      \n"   // 12   set LED off

    : // outputs
      [data] "+&a" (data),                      // in/out A-reg
      [count] "+&d" (count),                    // in/out D-reg
      [byte] "=&d" (byte),                      // temp D-reg
      [sck_lo] "=&d" (sck_lo),                  // temp D-reg
      [sck_hi] "=&d" (sck_hi),                  // temp D-reg
      [temp] "=&d" (temp)                       // temp D-reg
    : // inputs
      [gpdr] "a" (MFP_GPDR),                    // GPDR addr A-reg
      [cipobit] "d" (SPI_CIPO_B),               // CIPO bit # D-reg
      [sck] "n" (SPI_SCK),                      // SCK value
      [maskbits] "n" (~(SPI_SCK|SPI_LED)),      // SPI bit mask value
      [ledoff] "n" (SPI_LED)                    // LED off value
    : // clobbers (none)
  );
}

#endif  // _ROSCOM68K_GPIO_SPI_H
