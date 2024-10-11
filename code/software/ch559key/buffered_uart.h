/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|         libraries
 * ------------------------------------------------------------
 * Copyright (c)2024 The rosco_m68k OSP
 * See top-level LICENSE.md for licence information.
 *
 * Buffered (interrupt-driven) DUART support
 * 
 * NOT PUBLIC API!
 * ------------------------------------------------------------
 */

#ifndef __ROSCOM68K_LIBC_BUFFERED_UART_H__
#define __ROSCOM68K_LIBC_BUFFERED_UART_H__

#include <stdint.h>
#include <rosco_m68k/machine.h>

#include "ring_buffer.h"

/**
 * Pass NULL for either buffer to skip installing for that UART.
 * 
 * @param device A character device from the DUART chip you want to use
 * @param uart_a A buffer for UART A, or NULL for none
 * @param uart_b A buffer for UART B, or NULL for none
 */
void install_interrupt(CharDevice *device, RingBuffer *uart_a, RingBuffer *uart_b);

/**
 * Remove interrupt handler and restore the system to its original state.
 */
void remove_interrupt();

#endif//__ROSCOM68K_LIBC_BUFFERED_UART_H__
