#ifndef __BACKEND_H
#define __BACKEND_H

#include <stdint.h>
#include <stdbool.h>

#include "view.h"

typedef enum {
    NONE,
    QUIT,
    UP,
    DOWN
} BACKEND_EVENT;

typedef enum {
    COLOR_BLACK = 0,
    COLOR_WHITE,
    COLOR_YELLOW,
    COLOR_BACKGROUND,
    COLOR_BACKGROUND_SHADOW,
    COLOR_WINDOW_BACKGROUND,
    COLOR_SELECTION_BAR,
    COLOR_ITEM_TEXT,
    COLOR_ITEM_HIGHLIGHT_TEXT,
    COLOR_UNUSED1,
    COLOR_UNUSED2,
    COLOR_UNUSED3,
    COLOR_UNUSED4,
    COLOR_UNUSED5,
    COLOR_UNUSED6,
    COLOR_UNUSED7,
} BACKEND_COLOR;

typedef uintptr_t BACKEND_FONT_COOKIE;

bool backend_init(void);
void backend_clear(void);
void backend_set_color(BACKEND_COLOR color);
void backend_draw_pixel(int x, int y);
BACKEND_FONT_COOKIE backend_load_font(const uint8_t *font, int font_width, int font_height, int char_count);
void backend_text_write(const char *str, int x, int y, BACKEND_FONT_COOKIE font, int font_width, int font_height);
void backend_draw_rect(Rect *rect);
void backend_fill_rect(Rect *rect);
void backend_present(void);
uint32_t backend_get_ticks(void);
uint32_t backend_get_cpu(void);
uint32_t backend_get_cpu_mhz(void);
uint32_t backend_get_memsize(void);
BACKEND_EVENT backend_poll_event(void);
void backend_done(void);

#endif