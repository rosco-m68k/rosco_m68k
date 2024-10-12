/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|          firmware
 * ------------------------------------------------------------
 * Copyright (c)2024 The rosco_m68k OSP
 * See top-level LICENSE.md for licence information.
 *
 * General purpose ring buffer.
 * ------------------------------------------------------------
 */

#ifndef __ROSCOM68K_LIBC_RING_BUFFER_H__
#define __ROSCOM68K_LIBC_RING_BUFFER_H__

#include <stdint.h>

#define RING_BUFFER_SIZE        ((0x200))
#define RING_BUFFER_MASK        ((RING_BUFFER_SIZE-1))

typedef struct {
    uint16_t    r_ptr;
    uint16_t    w_ptr;
    uint16_t    mask;
    uint8_t     data[RING_BUFFER_SIZE];
} RingBuffer;

/**
 * Buffer a single character.
 * 
 * Does not check whether the buffer is full, and will never block,
 * so can potentially overwrite previously-buffered content.
 * 
 * @param rb        The ringbuffer
 * @param c         The character to buffer
 */
void ring_buffer_char(RingBuffer *rb, unsigned char c);

/**
 * Unbuffer waiting input from the given ringbuffer.
 * 
 * @param rb        The ringbuffer
 * @param buffer    A local buffer to unbuffer to (1KiB in size)
 * 
 * @return uint16_t the actual unbuffered count
 */
uint16_t ring_unbuffer(RingBuffer *rb, unsigned char *buffer);

/**
 * Unbuffer zero or one waiting characters from the given ringbuffer
 * 
 * @param rb        The ringbuffer
 * @param buffer    A local buffer to unbuffer to (1 byte in size)
 * 
 * @return uint16_t the actual unbuffered count (0 or 1)
 */
uint16_t ring_unbuffer_char(RingBuffer *rb, unsigned char *buffer);

/**
 * Determine if a ring buffer has data to unbuffer
 * 
 * @param rb        The ringbuffer
 * 
 * @return bool     True (strictly) if the read and write pointers are unequal
 */
static inline bool ring_buffer_ready(RingBuffer *rb) {
    return rb->r_ptr != rb->w_ptr;
}

#endif