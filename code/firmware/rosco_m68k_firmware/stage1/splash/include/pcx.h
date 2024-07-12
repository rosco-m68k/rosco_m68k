/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2021 Ross Bamford
 * MIT License
 *
 * PCX file format
 *
 * Note! All multi-byte members are little-endian.
 * ------------------------------------------------------------
 */

#ifndef __PCX_H
#define __PCX_H

#include <stdbool.h>
#include <stdint.h>

// Encoding constants
#define PCX_ENC_NONE        0
#define PCX_ENC_RLE         1

// Palette mode constants
#define PCX_PAL_MODE_NORM   1
#define PCX_PAL_MODE_GRAY   2

typedef struct {
    uint8_t     r;
    uint8_t     g;
    uint8_t     b;
} __attribute__((packed)) PalEntry;

typedef struct {
    uint8_t     header;
    uint8_t     version;
    uint8_t     encoding;
    uint8_t     bpp;
    uint16_t    min_x;
    uint16_t    min_y;
    uint16_t    max_x;
    uint16_t    max_y;
    uint16_t    h_dpi;
    uint16_t    v_dpi;
    PalEntry    ega_palette[16];
    uint8_t     reserved1;
    uint8_t     num_planes;
    uint16_t    line_size;
    uint16_t    palette_mode;
    uint16_t    source_hres;
    uint16_t    source_vres;
    uint8_t     reserved2[54];
} __attribute__((packed)) PCXHeader;

#define TO_RGB444(palentry) ((uint16_t) \
        (((palentry.r & 0xF0) << 4)     \
         | ((palentry.g) & 0xF0)        \
         | ((palentry.b) & 0xF0 >> 4)))

bool show_pcx(uint32_t buf_size, uint8_t *buf, uint8_t fade_delay);

#endif