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
 * rosco_m68k Bit-Banged SPI
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <gpio.h>
#include <gpio_spi.h>
#include "bbspi.h"

#ifndef SPI_ZERODELAY
static void delay(uint32_t nops) {
    for (uint32_t i = 0; i < nops; i++) {
        __asm__ __volatile__ ("nop");
    }
}
#endif

bool BBSPI_initialize(BBSPI *spi, GPIO cs, GPIO sck, GPIO mosi, GPIO miso) {
#ifndef SPI_FASTER
    if (spi->initialized) {
        return false;
    }
#endif

    spi->cs = cs;
    spi->sck = sck;
    spi->mosi = mosi;
    spi->miso = miso;

#ifndef SPI_ZERODELAY
    spi->sck_high_hold_nops = BBSPI_DEFAULT_SCK_HIGH_HOLD_NOPS;
    spi->sck_low_hold_nops = BBSPI_DEFAULT_SCK_LOW_HOLD_NOPS;
#endif

    pinMode(cs, OUTPUT);
    pinMode(sck, OUTPUT);
    pinMode(mosi, OUTPUT);
    pinMode(miso, INPUT);

#ifndef SPI_FASTER
    spi->initialized = true;
#endif
    return true;
}

#ifndef SPI_ZERODELAY
bool BBSPI_set_hold_times(BBSPI *spi, uint32_t high_hold_nops, uint32_t low_hold_nops) {
#ifndef SPI_FASTER
    if (!spi->initialized) {
        return false;
    }
#endif

    spi->sck_high_hold_nops = high_hold_nops;
    spi->sck_low_hold_nops = low_hold_nops;

    return true;
}
#endif

void BBSPI_assert_cs(BBSPI *spi) {
#ifndef SPI_FASTER
    if (spi->initialized) {
#endif
        digitalWrite(spi->cs, false);
#ifndef SPI_FASTER
    }
#endif
}

void BBSPI_deassert_cs(BBSPI *spi) {
#ifndef SPI_FASTER
    if (spi->initialized) {
#endif
        digitalWrite(spi->cs, true);
#ifndef SPI_FASTER
    }
#endif
}

void BBSPI_write_mosi(BBSPI *spi, bool state) {
#ifndef SPI_FASTER
    if (spi->initialized) {
#endif
        digitalWrite(spi->mosi, state);
#ifndef SPI_FASTER
    }
#endif
}

void BBSPI_write_sck(BBSPI *spi, bool state) {
#ifndef SPI_FASTER
    if (spi->initialized) {
#endif
        digitalWrite(spi->sck, state);
#ifndef SPI_FASTER
    }
#endif
}

bool BBSPI_read_miso(BBSPI *spi) {
#ifndef SPI_FASTER
    if (spi->initialized) {
#endif
        return digitalRead(spi->miso);
#ifndef SPI_FASTER
    } else {
        return false;
    }
#endif
}

uint8_t BBSPI_transfer_byte(BBSPI *spi, uint8_t byte_out) {
#ifndef SPI_FASTER
    if (!spi->initialized) {
        return 0;
    }
#endif
    return spi_exchange_byte(byte_out);
}

void BBSPI_send_byte(BBSPI *spi, uint8_t byte_out) {
#ifndef SPI_FASTER
    if (spi->initialized) {
#endif
        return spi_send_byte(byte_out);
#ifndef SPI_FASTER
    }
#endif
}

uint8_t BBSPI_recv_byte(BBSPI *spi) {
#ifndef SPI_FASTER
    if (!spi->initialized) {
        return 0;
    }
#endif
    return spi_read_byte();
}

size_t BBSPI_recv_buffer(BBSPI *spi, void *buffer, size_t count) {
#ifndef SPI_FASTER
    if (!spi->initialized) {
        return 0;
    }
#endif
    spi_read_buffer(buffer, count);
    return count;
}
