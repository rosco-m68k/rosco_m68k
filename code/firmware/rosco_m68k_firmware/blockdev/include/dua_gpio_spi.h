/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2021 Ross Bamford
 * MIT License
 *
 * Routines for SPI mode 2 (CPOL=1, CPHA=1)
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_GPIO_SPI_H
#define _ROSCOM68K_GPIO_SPI_H

#include <machine.h>

#define USE_ASM_DUART_SPI   1   // Xark - set to 1 to use optimized asm routines
// firmware SPI functions are static inline and always inlined
#define SPI_INLINE inline __attribute__ ((always_inline))

#define pinMode(...)
#define INPUT   0
#define OUTPUT  0

// Default rosco 2.x SPI pins
#if !defined(SPI_CS_B)
#define SPI_CS_B      2         // Output port pin
#endif
#if !defined(SPI_SCK_B)
#define SPI_SCK_B     4         // Output port pin
#endif
#if !defined(SPI_COPI_B)
#define SPI_COPI_B    6         // Output port pin
#endif
#if !defined(SPI_CIPO_B)
#define SPI_CIPO_B    2         // Input port pin
#endif
#if !defined(SPI_CS1_B)
#define SPI_CS1_B     7         // Output port pin
#endif

// calculate bit values for bit positions
#define SPI_CS        (1<<SPI_CS_B)
#define SPI_CS1       (1<<SPI_CS1_B)
#define SPI_SCK       (1<<SPI_SCK_B)
#define SPI_COPI      (1<<SPI_COPI_B)
#define SPI_CIPO      (1<<SPI_CIPO_B)

// HI/LO refer to physical pin state, these ports are active
// low, so they appear reversed here...
static volatile uint8_t *DUART_OUTLOPORT = (uint8_t*)DUART_W_OPR_SETCMD;
static volatile uint8_t *DUART_OUTHIPORT = (uint8_t*)DUART_W_OPR_RESETCMD;
static volatile uint8_t *DUART_INPUTPORT = (uint8_t*)DUART_R_INPUTPORT;

static SPI_INLINE void digitalWrite(uint8_t pinmask, bool value) {
    if (value) {
        *DUART_OUTHIPORT = pinmask;
    } else {
        *DUART_OUTLOPORT = pinmask;
    }
}

static SPI_INLINE bool digitalRead(uint8_t pinmask) {
    return ((*DUART_INPUTPORT) & pinmask);
}

// send one SPI byte, ignore received byte
#if USE_ASM_DUART_SPI
extern void spi_send_byte(int byte);
#else
static SPI_INLINE void spi_send_byte(int byte) __attribute__ ((used));
static SPI_INLINE void spi_send_byte(int byte)
{
    if (byte & 128) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 64) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 32) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 16) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 8) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 4) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 2) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 1) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;
}
#endif

// send "count" SPI bytes (> 0) from data, ignore received bytes
#if USE_ASM_DUART_SPI
extern void spi_send_buffer(void* data, int count);
#else
static SPI_INLINE void spi_send_buffer(void* data, int count) __attribute__ ((used));
static SPI_INLINE void spi_send_buffer(void* data, int count)
{
    // Turn on Red LED
    *DUART_OUTLOPORT = 8;

    for (int i = 0; i < count; i++) {
        spi_send_byte(((uint8_t*)data)[i]);
    }

    // Turn off Red LED
    *DUART_OUTHIPORT = 8;
}
#endif

// send one SPI byte and receive one SPI byte
static SPI_INLINE int spi_exchange_byte(int byte) __attribute__ ((used));
static SPI_INLINE int spi_exchange_byte(int byte)
{
    uint8_t obyte = 0;

    if (byte & 128) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 128;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 64) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 64;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 32) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 32;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 16) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 16;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 8) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 8;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 4) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 4;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 2) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 2;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    if (byte & 1) {
        // output high data, followed by low clock
        *DUART_OUTHIPORT = SPI_COPI;
        *DUART_OUTLOPORT = SPI_SCK;
    } else {
        // output low and clock at once
        *DUART_OUTLOPORT = SPI_COPI | SPI_SCK;
    }

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 1;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    return obyte;
}

// send "count" SPI bytes (> 0) from data, and store "count" received bytes into data
static SPI_INLINE void spi_exchange_buffer(void *data, int count) __attribute__ ((used));
static SPI_INLINE void spi_exchange_buffer(void *data, int count)
{
    uint8_t *bd = (uint8_t*)data;
    // Turn on Red LED
    *DUART_OUTLOPORT = 8;

    for (int i = 0; i < count; i++) {
        bd[i] = spi_exchange_byte(bd[i]);
    }

    // Turn off Red LED
    *DUART_OUTHIPORT = 8;
}

// reads one SPI byte, sends one dummy 0xff byte,
#if USE_ASM_DUART_SPI
extern int spi_read_byte(void);
#else
static SPI_INLINE int spi_read_byte(void) __attribute__ ((used));
static SPI_INLINE int spi_read_byte(void)
{
    uint8_t byte = 0;

    // Send clock low
    *DUART_OUTLOPORT = SPI_SCK;

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 128;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    // Send clock low
    *DUART_OUTLOPORT = SPI_SCK;

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 64;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    // Send clock low
    *DUART_OUTLOPORT = SPI_SCK;

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 32;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    // Send clock low
    *DUART_OUTLOPORT = SPI_SCK;

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 16;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    // Send clock low
    *DUART_OUTLOPORT = SPI_SCK;

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 8;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    // Send clock low
    *DUART_OUTLOPORT = SPI_SCK;

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 4;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    // Send clock low
    *DUART_OUTLOPORT = SPI_SCK;

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 2;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    // Send clock low
    *DUART_OUTLOPORT = SPI_SCK;

    // Read bit
    if (((*DUART_INPUTPORT) & SPI_CIPO)) {
        byte |= 1;
    }

    // Send clock high again
    *DUART_OUTHIPORT = SPI_SCK;

    return byte;
}
#endif

// reads "count" SPI bytes (> 0) into data, sends "count" dummy 0xff bytes
#if USE_ASM_DUART_SPI   // Xark - use asm version
extern void spi_read_buffer(void *data, int count);
#else
static SPI_INLINE void spi_read_buffer(void *data, int count) __attribute__ ((used));
static SPI_INLINE void spi_read_buffer(void *data, int count)
{
    uint8_t *bd = (uint8_t*)data;

    // Turn on Red LED
    *DUART_OUTLOPORT = 8;

    for (int i = 0; i < count; i++) {
        bd[i] = spi_read_byte();
    }

    // Turn off Red LED
    *DUART_OUTHIPORT = 8;
}
#endif

#endif  // _ROSCOM68K_GPIO_SPI_H
