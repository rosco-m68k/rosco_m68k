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

#include "../../blockdev/include/gpio.h"

bool BBSPI_initialize();
void BBSPI_write_mosi(bool state);
void BBSPI_write_sck(bool state);
bool BBSPI_read_miso();
void BBSPI_assert_cs0();
void BBSPI_deassert_cs0();
void BBSPI_assert_cs1();
void BBSPI_deassert_cs1();
uint8_t BBSPI_transfer_byte(uint8_t byte_out);
size_t BBSPI_transfer_buffer(void *buffer, size_t count);
void BBSPI_send_byte(uint8_t byte_out);
uint8_t BBSPI_recv_byte();
size_t BBSPI_recv_buffer(void *buffer, size_t count);
size_t BBSPI_send_buffer(void *buffer, size_t count);

#endif /* ROSCO_M68K_BBSD_H */
