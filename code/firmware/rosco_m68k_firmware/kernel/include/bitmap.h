/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|            kernel
 * ------------------------------------------------------------
 * Copyright (c)2023 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * General bitmap
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_KERNEL_BITMAP_H
#define _ROSCOM68K_KERNEL_BITMAP_H

#include <stdint.h>

/**
 * Set a bit in the given bitmap. Not limited to a
 * single 32-bit - the bitmap can be arbitrarily 
 * large (well, up to 2**32 bits).
 * 
 * @param bitmap Pointer to the bitmap
 * @param bit The bit number to set
 */
void bitmap_set_c(uint32_t *bitmap, uint32_t bit);

/**
 * Clear a bit in the given bitmap. Not limited to a
 * single 32-bit - the bitmap can be arbitrarily 
 * large (well, up to 2**32 bits).
 * 
 * @param bitmap Pointer to the bitmap
 * @param bit The bit number to clear
 */
void bitmap_clear_c(uint32_t *bitmap, uint32_t bit);

/**
 * Flip a bit in the given bitmap. Not limited to a
 * single 32-bit - the bitmap can be arbitrarily 
 * large (well, up to 2**32 bits).
 * 
 * @param bitmap Pointer to the bitmap
 * @param bit The bit number to flip
 */
void bitmap_flip_c(uint32_t *bitmap, uint32_t bit);

/**
 * Find a clear bit in a 32-bit bitmap.
 *
 * Makes no guarantee on ordering.
 * 
 * Note! Supports only a single uint32 - it's up
 * to the caller to loop through larger bitmaps
 * if needed.
 * 
 * @param bitmap The 32-bit bitmap
 * @return uint8_t A clear bit number, or -1 if none
 */
int32_t bitmap_find_clear_c(uint32_t bitmap);

/**
 * Find n consecutive clear bits in a 32-bit bitmap.
 *
 * Makes no guarantee on ordering (but does guarantee
 * the bits are contiguous).
 * 
 * Note! Supports only a single uint32 - it's up
 * to the caller to loop through larger bitmaps
 * if needed.
 * 
 * @param bitmap The 32-bit bitmap
 * @return uint8_t First (lowest) bit number in a block of n clear bits, or -1 if none
 */
int32_t bitmap_find_n_clear_c(uint32_t bitmap, uint8_t n);

#endif//_ROSCOM68K_KERNEL_BITMAP_H
 