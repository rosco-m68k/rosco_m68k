/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|          firmware
 * ------------------------------------------------------------
 * Copyright (c)2024 The rosco_m68k Open Source Project
 * See top-level LICENSE.md for licence information.
 *
 * Xosera backend utility funcs (4bpp)
 * ------------------------------------------------------------
 */

#ifndef __XOSERA_BLIT_RECTS_H
#define __XOSERA_BLIT_RECTS_H

#include <stdint.h>

#include "backend.h"

#define BLIT_SHIFT_NIBBLE_MASK_LEFT     ((0xF000))
#define BLIT_SHIFT_NIBBLE_MASK_RIGHT    ((0x0F00))

// Overloading the term "subpixel" here to mean pixels _within_ a word.
// I don't know of a better term, but I imagine there is one...
#define SUBPIXEL_MASK                   ((0x03))

#define pixels_to_words(pixels)     (((pixels) >> 2))
#define pixel_to_word(pixel)        (((pixel) >> 2 << 2))

#define blit_shift(left_mask, right_mask, shift)        \
            ((((left_mask) << 12) & 0xF000) | (((right_mask) << 8) & 0x0F00) | ((shift) & 0x0002))

#define xosera_rect_start_word(rect, line_width_words)  \
            xosera_rect_start_word_v((rect)->x, (rect)->y, (line_width_words))

static inline uint16_t xosera_rect_start_word_v(uint16_t x, uint16_t y, uint16_t line_width_words) {
    return y * line_width_words + pixels_to_words(x);
}

static inline uint16_t xosera_fill_rect_blit_shift_v(uint16_t x, uint16_t w) {
    uint16_t lb_mask;
    uint16_t rb_mask;

    // Writing this commeny because I missed an important thing initially...
    //
    // The right mask needs a bit of explanation here, as there's a nuance -
    // by starting with 0xF000 and shifting by the subpixel count, we end up
    // shifting the correct bits for the blitter into the most-significant bits
    // of the nibble that applies to the right-edge mask.
    //
    // Because this will leave that nibble at zero in the case where there are
    // no extra pixels (i.e. the rect finishes on a full-word boundary), this
    // means we can unconditionally just add one to the word count, and avoid 
    // special cases around rects with a width of 1, or where a 2-width
    // overlaps a word boundary, and all that other weirdness...
    //
    // Simple and elegant, thanks to @Xark 😀
    //
    lb_mask = (BLIT_SHIFT_NIBBLE_MASK_LEFT >> (x & SUBPIXEL_MASK)) & BLIT_SHIFT_NIBBLE_MASK_LEFT;
    rb_mask = (BLIT_SHIFT_NIBBLE_MASK_LEFT >> ((x + w) & SUBPIXEL_MASK)) & BLIT_SHIFT_NIBBLE_MASK_RIGHT;

#ifdef BLIT_DEBUG
    printf("LM: 0x%04x\nRM: 0x%04x\n", lb_mask, rb_mask);
#endif

    return (lb_mask | rb_mask);
}

static inline uint16_t xosera_fill_rect_blit_shift(Rect *rect) {
    return xosera_fill_rect_blit_shift_v(rect->x, rect->w);
}

#endif