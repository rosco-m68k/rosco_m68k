/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * rosco_m68k Bit-Banged SPI
 * ------------------------------------------------------------
 */


#include <stdbool.h>

#include "bbspi.h"

#ifdef REVISION1X
#include "mfp_gpio_spi.h"
#else
#include "dua_gpio_spi.h"
#endif

bool BBSPI_initialize() {
    pinMode(SPI_CS, OUTPUT);
    pinMode(SPI_CS1, OUTPUT);
    pinMode(SPI_SCK, OUTPUT);
    pinMode(SPI_COPI, OUTPUT);
    pinMode(SPI_CIPO, INPUT);

    return true;
}

void BBSPI_assert_cs0() {
    digitalWrite(SPI_CS, false);
}

void BBSPI_deassert_cs0() {
    digitalWrite(SPI_CS, true);
}

void BBSPI_assert_cs1() {
    digitalWrite(SPI_CS1, false);
}

void BBSPI_deassert_cs1() {
    digitalWrite(SPI_CS1, true);
}

void BBSPI_write_mosi(bool state) {
    digitalWrite(SPI_COPI, state);
}

void BBSPI_write_sck(bool state) {
    digitalWrite(SPI_SCK, state);
}

bool BBSPI_read_miso() {
    return digitalRead(SPI_CIPO);
}

uint8_t BBSPI_transfer_byte(uint8_t byte_out) {
    return spi_exchange_byte(byte_out);
}

size_t BBSPI_transfer_buffer(void *buffer, size_t count) {
    spi_exchange_buffer(buffer, count);
    return count;
}

void BBSPI_send_byte(uint8_t byte_out) {
    spi_send_byte(byte_out);
}

uint8_t BBSPI_recv_byte() {
    return spi_read_byte();
}

size_t BBSPI_recv_buffer(void *buffer, size_t count) {
    spi_read_buffer(buffer, count);
    return count;
}

size_t BBSPI_send_buffer(void *buffer, size_t count) {
    spi_send_buffer(buffer, count);
    return count;
}
