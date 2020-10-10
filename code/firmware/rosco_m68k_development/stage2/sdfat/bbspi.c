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

    // TODO this should be in bbsd, not here!
    digitalWrite(cs, true);

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

    uint8_t byte_in = 0;
    uint8_t bit;

    for (bit = 0x80; bit; bit >>= 1) {
        BBSPI_write_mosi(spi, (byte_out & bit));

#ifndef SPI_ZERODELAY
        delay(spi->sck_low_hold_nops);
#endif
        BBSPI_write_sck(spi, true);

        if (BBSPI_read_miso(spi)) {
            byte_in |= bit;
        }

#ifndef SPI_ZERODELAY
        delay(spi->sck_high_hold_nops);
#endif
        BBSPI_write_sck(spi, false);
    }

    return byte_in;
}

void BBSPI_send_byte(BBSPI *spi, uint8_t byte_out) {
#ifndef SPI_FASTER
    if (spi->initialized) {
#endif

    uint8_t bit;

    for (bit = 0x80; bit; bit >>= 1) {
        BBSPI_write_mosi(spi, (byte_out & bit));

#ifndef SPI_ZERODELAY
        delay(spi->sck_low_hold_nops);
#endif
        BBSPI_write_sck(spi, true);

#ifndef SPI_ZERODELAY
        delay(spi->sck_high_hold_nops);
#endif
        BBSPI_write_sck(spi, false);
    }

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

    uint8_t byte_in = 0;
    uint8_t bit;

    BBSPI_write_mosi(spi, 1);

    for (bit = 0x80; bit; bit >>= 1) {
#ifndef SPI_ZERODELAY
        delay(spi->sck_low_hold_nops);
#endif
        BBSPI_write_sck(spi, true);

        if (BBSPI_read_miso(spi)) {
            byte_in |= bit;
        }

#ifndef SPI_ZERODELAY
        delay(spi->sck_high_hold_nops);
#endif
        BBSPI_write_sck(spi, false);
    }

    return byte_in;
}
