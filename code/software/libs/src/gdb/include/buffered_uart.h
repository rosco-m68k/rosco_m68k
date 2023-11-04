/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|         libraries
 * ------------------------------------------------------------
 * Copyright (c)2023 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Buffered (interrupt-driven) DUART support
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_BUFFERED_UART_H
#define _ROSCOM68K_BUFFERED_UART_H

#include <stdint.h>
#include <machine.h>

typedef struct {
    uint16_t    r_ptr;
    uint16_t    w_ptr;
    uint16_t    mask;
    uint8_t     data[1024];
} RingBuffer;

/**
 * Pass NULL for either buffer to skip installing for that UART.
 * 
 * @param device A character device from the DUART chip you want to use
 * @param uart_a A buffer for UART A, or NULL for none
 * @param uart_b A buffer for UART B, or NULL for none
 */
void duart_install_interrupt(CharDevice *device, RingBuffer *uart_a, RingBuffer *uart_b);

/**
 * Remove interrupt handler and restore the system to its original state.
 */
void duart_remove_interrupt();

/**
 * Unbuffer waiting input from the given ringbuffer.
 * 
 * @param rb The ringbuffer
 * @param buffer A local buffer to unbuffer to (1KiB in size)
 * 
 * @return uint16_t the actual unbuffered count
 */
uint16_t duart_unbuffer(RingBuffer *rb, unsigned char *buffer);

/**
 * Unbuffer zero or one waiting characters from the given ringbuffer
 * 
 * @param rb The ringbuffer
 * @param buffer A local buffer to unbuffer to (1 byte in size)
 * 
 * @return uint16_t the actual unbuffered count (0 or 1)
 */
uint16_t duart_unbuffer_one(RingBuffer *rb, unsigned char *buffer);

#endif//_ROSCOM68K_BUFFERED_UART_H
