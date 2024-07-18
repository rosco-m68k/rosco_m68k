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

#ifndef __VIEW_H
#define __VIEW_H

#include <stdint.h>
#include <stdbool.h>
#include "model.h"

#include "config.h"

/*
 * Resolution-specific defines
 */
#if (VIEW_HRES == 320) 
#ifdef ALWAYS_BIZCAT
#include "bizcat_font.h"
#else
#include "topaz_font.h"
#endif
#define BOX_WIDTH       ((VIEW_HRES/1.4))       /* Width of the box */
#define LINE_HEIGHT_EX  2                       /* Just allows line height adjustment per resolution */
#define COPYRIGHT_MAX   38                      /* Max characters in copyright before overflow */
#elif (VIEW_HRES == 424)
#ifdef ALWAYS_BIZCAT
#include "bizcat_font.h"
#else
#include "topaz_font.h"
#endif
#define BOX_WIDTH       ((VIEW_HRES/1.8))       /* Width of the box */
#define LINE_HEIGHT_EX  2                       /* Just allows line height adjustment per resolution */
#define COPYRIGHT_MAX   48                      /* Max characters in copyright before overflow */
#elif (VIEW_HRES == 640)
#ifdef ALWAYS_TOPAZ
#include "topaz_font.h"
#else
#include "bizcat_font.h"
#endif
#define BOX_WIDTH       ((VIEW_HRES/1.8))       /* Width of the box */
#define LINE_HEIGHT_EX  0                       /* Just allows line height adjustment per resolution */
#define COPYRIGHT_MAX   58                      /* Max characters in copyright before overflow */
#elif (VIEW_HRES == 848)
#ifdef ALWAYS_TOPAZ
#include "topaz_font.h"
#else
#include "bizcat_font.h"
#endif
#define BOX_WIDTH       ((VIEW_HRES/3.0))       /* Width of the box */
#define LINE_HEIGHT_EX  0                       /* Just allows line height adjustment per resolution */
#define COPYRIGHT_MAX   88                      /* Max characters in copyright before overflow */
#else
#error Unknown resolution - add settings to view.h
#endif

#include "num_font.h"

/*
 * Font-specific defines
 */
#if defined(FONT_BIZCAT)
#define COPYRIGHT       "\xaf" "2024 rosco_m68k\xae Contributors"
#define BOX_TITLE       "rosco_m68k\xae"
#elif defined(FONT_TOPAZ)
#define COPYRIGHT       "\x88" "2024 rosco_m68k\x8d Contributors"
#define BOX_TITLE       "rosco_m68k\x8d"
#endif

/*
 * Res/font independent calculated values
 */
#define MIN_PADDING     ((LINE_HEIGHT * 1.5))       // at top and bottom of screen
#define LINE_HEIGHT     ((FONT_HEIGHT + (FONT_HEIGHT / 4 + LINE_HEIGHT_EX)))
#define LINE_PAD        (((FONT_HEIGHT / 8) + (LINE_HEIGHT_EX / 2)))
#define SHADOW_OFFSET   ((VIEW_HRES / 80))

typedef struct {
    int x, y, w, h;
} Rect;

typedef struct {
    Rect    main_box;
    Rect    main_box_header;
    Rect    right_shadow;
    Rect    bottom_shadow;
    Model*  model;
} View;

void view_init(View *view, Model *model);
void view_recompute_size(View *view, Model *model);
void view_repaint(View *view, bool force);

#endif
