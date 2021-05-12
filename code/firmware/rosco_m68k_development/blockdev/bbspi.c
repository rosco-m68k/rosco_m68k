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
#include "gpio.h"
#include "gpio_spi.h"

#define CS0     GPIO1
#define SCK     GPIO2
#define MOSI    GPIO3
#define MISO    GPIO4
#define CS1     GPIO5

bool BBSPI_initialize() {
    pinMode(CS0, OUTPUT);
    pinMode(CS1, OUTPUT);
    pinMode(SCK, OUTPUT);
    pinMode(MOSI, OUTPUT);
    pinMode(MISO, INPUT);

    return true;
}

void BBSPI_assert_cs0() {
    digitalWrite(CS0, false);
}

void BBSPI_deassert_cs0() {
    digitalWrite(CS0, true);
}

void BBSPI_assert_cs1() {
    digitalWrite(CS1, false);
}

void BBSPI_deassert_cs1() {
    digitalWrite(CS1, true);
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
