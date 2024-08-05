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
 * View for concept boot screen
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <string.h>

#include "view.h"
#include "model.h"

#include "backend.h"

#include "debug.h"

#define MAX_BOX_HEIGHT  ((VIEW_VRES-(MIN_PADDING*2)))
#define CHAR_BUF_SIZE   18

#define STR_MB_RAM      "MB RAM"
#define STR_MC          "MC"
#define STR_AT          " @ "
#define STR_MHZ         "MHZ"

static Model current;

#ifdef ENABLE_TIMER
static char secs_buf[2];
#endif

static char cpu_buffer[CHAR_BUF_SIZE];
static char mem_buffer[CHAR_BUF_SIZE];
static uint8_t cpu_buffer_len;
static uint8_t copyright_len;

static BACKEND_FONT_COOKIE regular_font;
static BACKEND_FONT_COOKIE small_font;

#ifdef TEST_PATTERN_DEBUG
extern bool use_ruler;
#endif

static int uintToStr(char *buffer, unsigned int num, int bufferSize) {
    int i = 0;
    int len = 0;
    
    // Extract digits and store them in reverse order in the buffer
    do {
        buffer[i++] = (num % 10) + '0';
        num /= 10;
    } while (num > 0 && i < bufferSize - 1);
    
    len = i;
    buffer[i] = '\0';
    
    // Reverse the string
    for (int j = 0, k = i - 1; j < k; j++, k--) {
        char temp = buffer[j];
        buffer[j] = buffer[k];
        buffer[k] = temp;
    }

    return len;
}

void view_init(View *view, Model *model) {
    view->model = model;

    // I know you want to pull in snprintf etc here, but don't - doing this saves us ~30K...
    memset(mem_buffer, 0, CHAR_BUF_SIZE);
    memset(cpu_buffer, 0, CHAR_BUF_SIZE);

    int len = uintToStr(mem_buffer, model->mem_count / 1048576, CHAR_BUF_SIZE);
    memcpy(mem_buffer + len, STR_MB_RAM, strlen(STR_MB_RAM));     // safe(ish)- buf can hold max int

    len = strlen(STR_MC);
    memcpy(cpu_buffer, STR_MC, len);
    len += uintToStr(cpu_buffer + len, model->cpu, CHAR_BUF_SIZE - len);
    memcpy(cpu_buffer + len, STR_AT, strlen(STR_AT));
    len += strlen(STR_AT);
    len += uintToStr(cpu_buffer + len, model->mhz, CHAR_BUF_SIZE - len);
    memcpy(cpu_buffer + len, STR_MHZ, strlen(STR_MHZ));
    cpu_buffer_len = len + strlen(STR_MHZ);

    copyright_len = strlen(COPYRIGHT);

    regular_font = backend_load_font(FONT, 8, 16, 256);
    small_font = backend_load_font(NUM_FONT, 8, 8, 6);

    view_recompute_size(view, model);
}

void view_recompute_size(View *view, Model *model) {
    int main_box_height = LINE_HEIGHT * (model->n_items + 1);

    if (main_box_height > MAX_BOX_HEIGHT) {
        model->n_items = MAX_BOX_HEIGHT / LINE_HEIGHT - 1;
        main_box_height = LINE_HEIGHT * (model->n_items + 1);
        debugf("WARN: Adjusted n_items to %d for height\n", model->n_items);
    }

    view->main_box.x = VIEW_HRES / 2 - BOX_WIDTH / 2;
    view->main_box.y = VIEW_VRES / 2 - main_box_height / 2;
    view->main_box.w = BOX_WIDTH;
    view->main_box.h = main_box_height;

    view->main_box_header.x = view->main_box.x;
    view->main_box_header.y = view->main_box.y;
    view->main_box_header.w = view->main_box.w;
    view->main_box_header.h = LINE_HEIGHT;

    view->right_shadow.x = view->main_box.x + view->main_box.w;
    view->right_shadow.y = view->main_box.y + SHADOW_OFFSET;
    view->right_shadow.w = SHADOW_OFFSET;
    view->right_shadow.h = view->main_box.h;

    view->bottom_shadow.x = view->main_box.x + SHADOW_OFFSET;
    view->bottom_shadow.y = view->main_box.y + view->main_box.h;
    view->bottom_shadow.w = view->main_box.w;
    view->bottom_shadow.h = SHADOW_OFFSET;
}

#ifdef __ROSCO_M68K_ROM__
#define debug_model_update(...)
#else
#ifdef MODEL_DEBUG
void debug_model_update(Model *model) {
    debugf("Model updated:\n");
    debugf("    selection: 0x%02x\n", model->selection);
    debugf("    secs_left: 0x%02x\n", model->timer_secs_left);
    debugf("    items_ptr: %p\n", model->items);
    debugf("    n_items  : %d\n", model->n_items);

#   ifdef ENABLE_ANIM
    debugf("  anim_dirty : %d\n", model->anim_list_dirty);
    debugf("  anim_front : %p\n", model->animations_front.next);
    debugf("   anim_back : %p\n", model->animations_back.next);
#   endif

    debugf("\n");
}
#else
#define debug_model_update(...)
#endif
#endif

#ifdef ENABLE_ANIM
static void paint_anim_layer(Animation *current_anim) {
    while (current_anim) {
        // Don't check dirty, always paint anims when painting.
        // **do** set dirty false though, in case the anim was what triggered this repaint...
        current_anim->paint(current_anim);
        current_anim->dirty = false;
        current_anim = (Animation*)current_anim->node.next;
    }
}
#else
#define paint_anim_layer(...)
#endif

void view_repaint(View *view, bool force) {
    if (force || model_is_dirty(&current, view->model)) {        
        debug_model_update(view->model);

        backend_set_color(COLOR_BACKGROUND);
        backend_clear();

        // Sysinfo header
        backend_set_color(COLOR_BACKGROUND_SHADOW);
        backend_text_write(mem_buffer, 6, 6, regular_font, FONT_WIDTH, FONT_HEIGHT);
        backend_text_write(cpu_buffer, VIEW_HRES - (cpu_buffer_len * FONT_WIDTH) - 6, 6, regular_font, FONT_WIDTH, FONT_HEIGHT);

        // Copyright footer
        backend_text_write(COPYRIGHT, VIEW_HRES - (copyright_len * FONT_WIDTH) - 6, VIEW_VRES - LINE_HEIGHT, regular_font, FONT_WIDTH, FONT_HEIGHT);

        // Animations (back)
        paint_anim_layer((Animation*)view->model->animations_back.next);

        // Main box
        backend_set_color(COLOR_WINDOW_BACKGROUND);
        backend_fill_rect(&view->main_box);

        backend_set_color(COLOR_BLACK);
        backend_draw_rect(&view->main_box);
        backend_fill_rect(&view->main_box_header);

        // Shadow
        backend_set_color(COLOR_BACKGROUND_SHADOW);
        backend_fill_rect(&view->right_shadow);
        backend_fill_rect(&view->bottom_shadow);

        // Header text
        backend_set_color(COLOR_WHITE);
        backend_text_write(BOX_TITLE, view->main_box_header.x + 4, view->main_box_header.y + 2, regular_font, FONT_WIDTH, FONT_HEIGHT);

        backend_set_color(COLOR_YELLOW);
        backend_text_write(VERSION, view->main_box_header.x + view->main_box_header.w - 4 - (strlen(VERSION) * FONT_WIDTH), view->main_box_header.y + 2, regular_font, FONT_WIDTH, FONT_HEIGHT);

        // Selection bar
        Rect selection_rect;
        selection_rect.x = view->main_box.x + 1;
        selection_rect.y = view->main_box.y + view->main_box_header.h + (LINE_HEIGHT * current.selection);
        selection_rect.w = view->main_box.w - 2;
        selection_rect.h = LINE_HEIGHT - 1;  // -1 so as not to overdraw border on last item!
        backend_set_color(COLOR_SELECTION_BAR);
        backend_fill_rect(&selection_rect);

        // Items text
        backend_set_color(COLOR_ITEM_TEXT);
        int y = view->main_box_header.y + view->main_box_header.h + LINE_PAD;

        for (int i = 0; i < view->model->n_items; i++) {
#           ifdef CENTER_ITEMS
            int x = view->main_box.x + (view->main_box.w / 2) - (strlen(view->model->items[i]) * FONT_WIDTH / 2);
            #else
            int x = view->main_box_header.x + 4;
#           endif

#           ifdef HIGHLIGHT_SELECTION
            if (i == current.selection) {
                backend_set_color(COLOR_ITEM_HIGHLIGHT_TEXT);
            }
#           endif

            backend_text_write(view->model->items[i], x, y, regular_font, FONT_WIDTH, FONT_HEIGHT);

#           ifdef HIGHLIGHT_SELECTION
            if (i == current.selection) {
                backend_set_color(COLOR_ITEM_TEXT);
            }
#           endif

            y += LINE_HEIGHT;
        }

#       ifdef ENABLE_TIMER
        // ticks remaining
        if (view->model->timer_secs_left) {
            secs_buf[0] = view->model->timer_secs_left;
            backend_set_color(COLOR_YELLOW);
            backend_text_write(secs_buf, selection_rect.x + selection_rect.w - 12, selection_rect.y + 2, small_font, NUM_FONT_WIDTH, NUM_FONT_HEIGHT);
        }
#       endif

        // TODO redrawing the outline, since something (I suspect maybe text _somehow_?) is overdrawing the left line of the one drawn above.
        //      Weirdly, _removing_ the one above caused some serious corruption, but repeating is fine. Could suggest maybe we're not 
        //      properly setting all blitter registers or something, needs investigating...
        //
        //      would be nice to figure out what / why, since it's a bug _somewhere_ (it doesn't happen with SDL2 backend)
        //
        backend_set_color(COLOR_BLACK);
        backend_draw_rect(&view->main_box);

        // Animations (front)
        paint_anim_layer((Animation*)view->model->animations_front.next);

#       ifdef TEST_PATTERN_DEBUG
        use_ruler = true;
        Rect ruler = { .x = 0, .y = 30, .w = 20, .h = 2 };
        backend_set_color(COLOR_WHITE);
        backend_fill_rect(&ruler);
        
        use_ruler = false;
        Rect test1 = { .x = 0, .y = 32, .w = 4, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test1);

        Rect test2 = { .x = 0, .y = 35, .w = 5, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test2);

        Rect test3 = { .x = 0, .y = 38, .w = 6, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test3);

        Rect test4 = { .x = 0, .y = 41, .w = 7, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test4);

        Rect test5 = { .x = 0, .y = 44, .w = 8, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test5);

        Rect test6 = { .x = 1, .y = 47, .w = 8, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test6);

        Rect test7 = { .x = 2, .y = 50, .w = 8, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test7);

        Rect test8 = { .x = 0, .y = 53, .w = 1, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test8);

        Rect test9 = { .x = 1, .y = 56, .w = 1, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test9);

        Rect test10 = { .x = 2, .y = 59, .w = 1, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test10);

        Rect test11 = { .x = 3, .y = 62, .w = 1, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test11);

        Rect test12 = { .x = 4, .y = 65, .w = 1, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test12);

        Rect test13 = { .x = 5, .y = 68, .w = 1, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test13);

        Rect test14 = { .x = 6, .y = 71, .w = 1, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test14);

        Rect test15 = { .x = 7, .y = 74, .w = 1, .h = 2 };
        backend_set_color(COLOR_YELLOW);
        backend_fill_rect(&test15);

        backend_text_write("TEST[0,150]", 0, 150, regular_font, FONT_WIDTH, FONT_HEIGHT);
        backend_text_write("TEST[1,170]", 1, 170, regular_font, FONT_WIDTH, FONT_HEIGHT);
        backend_text_write("TEST[2,190]", 2, 190, regular_font, FONT_WIDTH, FONT_HEIGHT);
        backend_text_write("TEST[3,210]", 3, 210, regular_font, FONT_WIDTH, FONT_HEIGHT);
        backend_text_write("TEST[4,230]", 4, 230, regular_font, FONT_WIDTH, FONT_HEIGHT);
#       endif

        backend_present();
    }
}
