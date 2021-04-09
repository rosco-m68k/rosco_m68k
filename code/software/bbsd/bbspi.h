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
 * rosco_m68k Bit-Banged SPI for SD Cards
 * ------------------------------------------------------------
 */

#ifndef ROSCO_M68K_BBSPI_H
#define ROSCO_M68K_BBSPI_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <gpio.h>

typedef struct {
#ifndef SPI_FASTER
    bool        initialized;
#endif
    GPIO        cs;
    GPIO        sck;
    GPIO        miso;
    GPIO        mosi;
#ifndef SPI_ZERODELAY
    uint32_t    sck_high_hold_nops;
    uint32_t    sck_low_hold_nops;
#endif
} BBSPI;

#ifndef SPI_ZERODELAY
/* We aren't fast enough to cause any concern... */
#define BBSPI_DEFAULT_SCK_HIGH_HOLD_NOPS    0
#define BBSPI_DEFAULT_SCK_LOW_HOLD_NOPS     0
bool BBSPI_set_hold_times(BBSPI *spi, uint32_t high_hold_nops, uint32_t low_hold_nops);
#endif

bool BBSPI_initialize(BBSPI *spi, GPIO cs, GPIO sck, GPIO mosi, GPIO miso);
void BBSPI_write_mosi(BBSPI *spi, bool state);
void BBSPI_write_sck(BBSPI *spi, bool state);
bool BBSPI_read_miso(BBSPI *spi);
void BBSPI_assert_cs(BBSPI *spi);
void BBSPI_deassert_cs(BBSPI *spi);
uint8_t BBSPI_transfer_byte(BBSPI *spi, uint8_t byte_out);
void BBSPI_send_byte(BBSPI *spi, uint8_t byte_out);
uint8_t BBSPI_recv_byte(BBSPI *spi);
size_t BBSPI_recv_buffer(BBSPI *spi, void *buffer, size_t count);

#endif /* ROSCO_M68K_BBSD_H */
