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

#define CS      GPIO1
#define SCK     GPIO2
#define MOSI    GPIO3
#define MISO    GPIO4

bool BBSPI_initialize() {
    pinMode(CS, OUTPUT);
    pinMode(SCK, OUTPUT);
    pinMode(MOSI, OUTPUT);
    pinMode(MISO, INPUT);

    return true;
}

void BBSPI_assert_cs() {
    digitalWrite(CS, false);
}

void BBSPI_deassert_cs() {
    digitalWrite(CS, true);
}

void BBSPI_write_mosi(bool state) {
    digitalWrite(MOSI, state);
}

void BBSPI_write_sck(bool state) {
    digitalWrite(SCK, state);
}

bool BBSPI_read_miso() {
    return digitalRead(MISO);
}

uint8_t BBSPI_transfer_byte(uint8_t byte_out) {
    return spi_exchange_byte(byte_out);
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
