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
 * Xosera backend for concept boot screen
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include <rosco_m68k/machine.h>

#ifndef XOSERA_STATIC
#define XOSERA_STATIC
#endif
#include <rosco_m68k/xosera_m68k_api.h>

#include "view.h"
#include "backend.h"

#include "xosera_blit_rects.h"

#if (VIEW_HRES == 640) || (VIEW_HRES == 848)
#error Xosera backend does not currently support high-resolution mode
#endif

// keep this defined until single-pixel fillrect is fixed for 1 pixel wide rects!
#define HACKED_LINE_DRAW

#define LINE_WIDTH_WORDS            ((VIEW_HRES >> 2))

#define BUFFER_SIZE                 ((VIEW_VRES * VIEW_HRES))
#define BUFFER_LONGS                ((BUFFER_SIZE / 4))

#define BLIT_COLOR(c)               (((c << 12) | (c << 8) | (c << 4) | c))
#ifdef TEST_PATTERN_DEBUG
#define BLIT_RULER(c)               (((c << 12) | (c << 4)))
#endif

#define XO_COLOR_BLACK              0xF000
#define XO_COLOR_WHITE              0xFFFF
#define XO_COLOR_YELLOW             0xFDD0
#define XO_COLOR_BACKGROUND         0xF234
#define XO_COLOR_BACKGROUND_SHADOW  0xF123
#define XO_COLOR_WINDOW_BACKGROUND  0xFCCC
#define XO_COLOR_SELECTION_BAR      0xF18A
#define XO_COLOR_ITEM_TEXT          0xF111
#define XO_COLOR_ITEM_HILITE_TEXT   0xFEEE

#if VIEW_HRES == 320
#define XO_PAGE_0_ADDR              0x0000
#define XO_PAGE_1_ADDR              0x4B00
#define XO_MAIN_FONT_ADDR           0x9600
#define XO_SMALL_FONT_ADDR          0xb600
#elif VIEW_HRES == 424
#define XO_PAGE_0_ADDR              0x0000
#define XO_PAGE_1_ADDR              0x6360
#define XO_MAIN_FONT_ADDR           0xC6C0
#define XO_SMALL_FONT_ADDR          0xE6C0
#else
#error Unknown resolution for Xosera backend - please configure in xosera_backed.c
#endif

#ifdef TEST_PATTERN_DEBUG
bool use_ruler = false;
#endif

volatile bool xosera_flip = false;
volatile uint32_t xosera_current_page = XO_PAGE_0_ADDR;

static uint8_t current_color;
static volatile uint32_t *tick_cnt = (uint32_t*)0x40c;
static volatile uint32_t *cpuinfo = (uint32_t*)0x41c;
static volatile uint32_t *memsize = (uint32_t*)0x414;

static uint16_t next_font_address;

#ifdef DEBUG_MENU_BACKEND
static void dputc(char c) {
#ifndef __INTELLISENSE__
    __asm__ __volatile__(
        "move.w %[chr],%%d0\n"
        "move.l #2,%%d1\n"        // SENDCHAR
        "trap   #14\n"
        :
        : [chr] "d"(c)
        : "d0", "d1");
#endif
}

static void dprint(const char * str) {
    register char c;
    while ((c = *str++) != '\0')
    {
        if (c == '\n')
        {
            dputc('\r');
        }
        dputc(c);
    }
}

static char dprint_buff[4096];
static void dprintf(const char * fmt, ...) __attribute__((__format__(__printf__, 1, 2)));
static void dprintf(const char * fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vsnprintf(dprint_buff, sizeof(dprint_buff), fmt, args);
    dprint(dprint_buff);
    va_end(args);
}
#else
#define dprintf(...)         ((void)(0))
#endif

static uint32_t expand_8_pixel_font_line(uint8_t line) {
    uint32_t result = 0;

    if (line & 0x80) {
        result |= 0xF0000000;
    }

    if (line & 0x40) {
        result |= 0x0F000000;
    }

    if (line & 0x20) {
        result |= 0x00F00000;
    }

    if (line & 0x10) {
        result |= 0x000F0000;
    }

    if (line & 0x08) {
        result |= 0x0000F000;
    }

    if (line & 0x04) {
        result |= 0x00000F00;
    }

    if (line & 0x02) {
        result |= 0x000000F0;
    }

    if (line & 0x01) {
        result |= 0x0000000F;
    }

    return result;
}

bool backend_init(void) {
    xv_prep();

#   if VIEW_HRES == 320
    dprintf("Calling xosera_init(XINIT_CONFIG_640x480)...");
    bool success = xosera_init(XINIT_CONFIG_640x480);
#   elif VIEW_HRES == 424
    dprintf("Calling xosera_init(XINIT_CONFIG_848x480)...");
    bool success = xosera_init(XINIT_CONFIG_848x480);
#   endif

    dprintf("%s (%dx%d)\n\n", success ? "succeeded" : "FAILED", xosera_vid_width(), xosera_vid_height());

    if (!success) {
        dprintf("Exiting without Xosera init.\n");
        exit(1);
    }

    xreg_setw(PA_GFX_CTRL, 0x0055);     /* 320x240 4bpp */
    xreg_setw(PA_DISP_ADDR, 0x0000);
    xreg_setw(PA_LINE_LEN, VIEW_HRES / 4);
    xm_setw(WR_INCR, 0x0001);
    
    xmem_setw_next_addr(XR_COLOR_A_ADDR);

    // Set up palette
    xmem_setw_next(XO_COLOR_BLACK);
    xmem_setw_next(XO_COLOR_WHITE);
    xmem_setw_next(XO_COLOR_YELLOW);
    xmem_setw_next(XO_COLOR_BACKGROUND);
    xmem_setw_next(XO_COLOR_BACKGROUND_SHADOW);
    xmem_setw_next(XO_COLOR_WINDOW_BACKGROUND);
    xmem_setw_next(XO_COLOR_SELECTION_BAR);
    xmem_setw_next(XO_COLOR_ITEM_TEXT);
    xmem_setw_next(XO_COLOR_ITEM_HILITE_TEXT);

    xosera_current_page = XO_PAGE_0_ADDR;
    xosera_flip = false;
    next_font_address = XO_MAIN_FONT_ADDR;

    mcDelaymsec10(200);

    return true;
}

void backend_clear(void) {
    xv_prep();

    uint16_t color = BLIT_COLOR(current_color);

#ifdef OPTIMISTIC_BLITTER
    xwait_blit_ready();
#endif

    xreg_setw(BLIT_CTRL,  0x0001);                      // no transp, s-const
    xreg_setw(BLIT_ANDC,  0x0000);                      // and-complement (0xffff)
    xreg_setw(BLIT_XOR,   0x0000);                      // xor with 0x0000
    xreg_setw(BLIT_MOD_S, 0x0000);                      // constant - irrelevant
    xreg_setw(BLIT_SRC_S, color);                       // fill with current color
    xreg_setw(BLIT_MOD_D, 0x0000);                      // No skip after each line - clear full screen
    xreg_setw(BLIT_DST_D, xosera_current_page);         // Clear current page
    xreg_setw(BLIT_SHIFT, 0xFF00);                      // No blit shift
    xreg_setw(BLIT_LINES, VIEW_VRES - 1);               // All the lines
    xreg_setw(BLIT_WORDS, (VIEW_HRES / 4) - 1);         // All the pixels (at 4bpp)

#ifndef OPTIMISTIC_BLITTER
    xwait_blit_done();
#endif
}

void backend_set_color(BACKEND_COLOR color) {
    current_color = color;
}

void backend_draw_pixel(__attribute__((unused)) int x, __attribute__((unused)) int y) {
    // Currently unused...
}

BACKEND_FONT_COOKIE backend_load_font(const uint8_t *font, int font_width, int font_height, int char_count) {
    if (font_width != 8) {
        // TODO only 8-pixel-wide fonts supported right now
        return 0;
    }

    xv_prep();

    // copy font
    xm_setw(WR_ADDR, next_font_address);
    for (int i = 0; i < font_height * char_count; i++) {
        uint32_t expanded_line = expand_8_pixel_font_line(font[i]);

        xm_setw(DATA, (uint16_t)((expanded_line & 0xFFFF0000) >> 16));
        xm_setw(DATA, (uint16_t)(expanded_line & 0x0000FFFF));
    }

    BACKEND_FONT_COOKIE cookie = (BACKEND_FONT_COOKIE) next_font_address;
    next_font_address += 2 * FONT_HEIGHT * 256;

    return cookie;
}

void backend_text_write(const char *str, int x, int y, BACKEND_FONT_COOKIE font, int font_width, int font_height) {
    const uint16_t blit_shift_s[4] = {0xF000, 0x7801, 0x3C02, 0x1E03};

    // TODO support different font (for small text)
    unsigned char c;

    xv_prep();

    uint16_t font_width_words = pixels_to_words(font_width) + 1;

    uint16_t blit_shift = blit_shift_s[x & 0x03]; //xosera_fill_rect_blit_shift_v(x, font_width) | shift;

    uint16_t line_mod = LINE_WIDTH_WORDS - font_width_words;
    uint16_t color_comp = ~(BLIT_COLOR(current_color));

    while ((c = *str++)) {
        const uint16_t font_ptr = ((uint16_t)font) + (c * font_height * 2);
        uint16_t start_word = xosera_rect_start_word_v(x, y, LINE_WIDTH_WORDS);

#ifdef OPTIMISTIC_BLITTER
        xwait_blit_ready();
#endif

        xreg_setw(BLIT_CTRL,  0x0010);                          // 0 transp, source mem
        xreg_setw(BLIT_ANDC,  color_comp);                      // and-complement (0xffff)
        xreg_setw(BLIT_XOR,   0x0000);                          // xor with 0x0000
        xreg_setw(BLIT_MOD_S, 0xFFFF);                          // source data is contiguous, -1 for extra word
        xreg_setw(BLIT_SRC_S, font_ptr);                        // fill with current color
        xreg_setw(BLIT_MOD_D, line_mod);                        // Skip to correct start word on next line
        xreg_setw(BLIT_DST_D, xosera_current_page + start_word);// Start at correct place for text
        xreg_setw(BLIT_SHIFT, blit_shift);                      // Use computed shift
        xreg_setw(BLIT_LINES, font_height - 1);                 // Whole font height (8 or 16)
        xreg_setw(BLIT_WORDS, font_width_words - 1);            // Full font width

#ifndef OPTIMISTIC_BLITTER
        xwait_blit_done();
#endif

        x += font_width;
    }
}

BACKEND_EVENT backend_poll_event(void) {
    if (mcCheckchar()) {
        switch (mcReadchar()) {
        // TODO support cursor escapes
        case 'w':
        case 'W':
            return UP;
        case 's':
        case 'S':
            return DOWN;
        case 0x0a:
        case 0x0d:
            return QUIT;
        }
    }
    return NONE;
}

uint32_t backend_get_ticks(void) {
    return *tick_cnt;
}

uint32_t backend_get_cpu(void) {
    switch (*cpuinfo & 0xE0000000) {
    case 0x20000000:
        return 68010;
    case 0x40000000:
        return 68020;
    case 0x60000000:
        return 68030;
    case 0x80000000:
        return 68040;
    case 0xA0000000:
        return 68060;
    default:
        return 68000;
    }
}

uint32_t backend_get_cpu_mhz(void) {
    return (*cpuinfo & 0x1FFFFFFF) / 10000;
}

uint32_t backend_get_memsize(void) {
    return *memsize;
}

static inline void rect_blit(
    uint16_t color,
    uint16_t line_mod,
    uint16_t start_word,
    uint16_t blit_shift,
    uint16_t height,
    uint16_t width_words
) {
    xv_prep();

#ifdef OPTIMISTIC_BLITTER
    xwait_blit_ready();
#endif

    xreg_setw(BLIT_CTRL,  0x0001);                              // no transp, s-const
    xreg_setw(BLIT_ANDC,  0x0000);                              // mask nothing, and-complement (0xffff)
    xreg_setw(BLIT_XOR,   0x0000);                              // xor with 0x0000
    xreg_setw(BLIT_MOD_S, 0x0000);                              // constant - irrelevant
    xreg_setw(BLIT_SRC_S, color);                               // fill with current color
    xreg_setw(BLIT_MOD_D, line_mod);                            // skip to next line based on rect size
    xreg_setw(BLIT_DST_D, xosera_current_page + start_word);    // Start at first word of rect
    xreg_setw(BLIT_SHIFT, blit_shift);                          // Use computed nibble masks
    xreg_setw(BLIT_LINES, height - 1);                          // Whole rect
    xreg_setw(BLIT_WORDS, width_words - 1);                     // All pixels in width

#ifndef OPTIMISTIC_BLITTER
    xwait_blit_done();
#endif
}

// TODO cannot handle rects < 1 word wide!
//      also inefficient (in part because fill_rect cannot handle the vertical lines)
void backend_draw_rect(Rect *rect) {    
    Rect line_rect;

#ifdef HACKED_LINE_DRAW
    uint16_t color = BLIT_COLOR(current_color);

    uint16_t x_start = rect->x;
    uint16_t x_end = rect->x + rect->w - 1;
    
    // Confusingly, left and right here refer to the left and right line of the rect,
    // **not** the left and right nibble masks in the blit shift register - we're
    // calculating two left-nibble masks...
    //
    uint16_t left_start_word = xosera_rect_start_word_v(x_start, rect->y, LINE_WIDTH_WORDS);
    uint16_t right_start_word = xosera_rect_start_word_v(x_end, rect->y, LINE_WIDTH_WORDS);

    uint16_t left_pixel_nibble = x_start - pixel_to_word(x_start);
    uint16_t right_pixel_nibble = x_end - pixel_to_word(x_end);

    uint16_t left_mask = (1 << (3-left_pixel_nibble));
    uint16_t right_mask = (1 << (3-right_pixel_nibble));

    uint16_t left_blit_shift = blit_shift(left_mask, left_mask, 0);
    uint16_t right_blit_shift = blit_shift(right_mask, right_mask, 0);

#ifdef BLIT_DEBUG
    dprintf("Unfilled rect: (%d, %d) (%d wide to %d)\n", x_start, rect->y, rect->w, x_end);
    dprintf("    Left mask  : 0x%04x\n", left_mask);
    dprintf("    Right mask : 0x%04x\n", right_mask);
    dprintf("    Left shift : 0x%04x\n", left_blit_shift);
    dprintf("    Right shift: 0x%04x\n", right_blit_shift);
    dprintf("\n");
#endif

    // left line
    rect_blit(
        color,
        LINE_WIDTH_WORDS - 1,       /* -1 for 1px vertical line width */
        left_start_word,
        left_blit_shift,
        rect->h,
        1
    );

    // right line
    rect_blit(
        color,
        LINE_WIDTH_WORDS - 1,       /* -1 for 1px vertical line width */
        right_start_word,
        right_blit_shift,
        rect->h,
        1
    );
#else
    // left line
    line_rect.x = rect->x;
    line_rect.y = rect->y;
    line_rect.w = 1;
    line_rect.h = rect->h;    
    backend_fill_rect(&line_rect);

    // right line
    line_rect.x = rect->x + rect->w;
    line_rect.y = rect->y;
    line_rect.w = 1;
    line_rect.h = rect->h;    
    backend_fill_rect(&line_rect);
#endif

    // top line
    line_rect.x = rect->x;
    line_rect.y = rect->y;
    line_rect.w = rect->w;
    line_rect.h = 1;    
    backend_fill_rect(&line_rect);

    // bottom line
    line_rect.x = rect->x;
    line_rect.y = rect->y + rect->h - 1;
    line_rect.w = rect->w;
    line_rect.h = 1;    
    backend_fill_rect(&line_rect);
}

// TODO cannot handle rects < 1 word wide!
void backend_fill_rect(Rect *rect) {
    uint16_t color;

#ifdef TEST_PATTERN_DEBUG
    if (use_ruler) {
        color = BLIT_RULER(current_color);        
    } else {
#endif
        color = BLIT_COLOR(current_color);
#ifdef TEST_PATTERN_DEBUG
    }
#endif

    uint16_t start_word = xosera_rect_start_word(rect, LINE_WIDTH_WORDS);
    uint16_t width_words = pixels_to_words(rect->w) + 1;

    if (rect->w & SUBPIXEL_MASK) {
        // Need a conditional extra word to cover "overspill" pixels when 
        // not finishing on a word boundary...
        width_words += 1;
    }

    uint16_t line_mod = LINE_WIDTH_WORDS - width_words;

    uint16_t blit_shift = xosera_fill_rect_blit_shift(rect);

#ifdef BLIT_DEBUG
    printf("[%d, %d -> %d, %d]: BLIT: 0x%04x word(s); BLITSHIFT: 0x%04x\n", rect->x, rect->y, rect->w, rect->h, width_words, blit_shift);
#endif

    rect_blit(
        color,
        line_mod,
        start_word,
        blit_shift,
        rect->h,
        width_words
    );
}

void backend_present(void) {
    xv_prep();

    while (xosera_flip) {
        // busywait, we're going too fast (unlikely)
        //
        // This isn't used yet anyhow...
    }

    xreg_setw(PA_DISP_ADDR, xosera_current_page);

    if (xosera_current_page == XO_PAGE_0_ADDR) {
        xosera_current_page = XO_PAGE_1_ADDR;
    } else {
        xosera_current_page = XO_PAGE_0_ADDR;
    }

    // TODO write ISR to do the flip in vblank...
}

void backend_done(void) {
    // This space intentionally left blank
}
