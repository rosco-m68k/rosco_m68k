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
 * Test / example animation for concept boot screen
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include "test_anim.h"
#include "view.h"

#include "config.h"

#include "backend.h"

#ifdef ENABLE_ANIM
bool test_anim_tick(__attribute__((unused)) uint32_t ticks, Animation *anim) {
    if (((TestAnimation*)anim)->next_y >= 230) {
        return false;
    }

    ((TestAnimation*)anim)->next_y += 1;
    ((TestAnimation*)anim)->animation.dirty = true;

    return true;
}

void test_anim_paint(Animation *anim) {
    Rect rect;
    rect.x = 100;
    rect.y = ((TestAnimation*)anim)->next_y;
    rect.w = 10;
    rect.h = 10;

    backend_fill_rect(&rect);
}
#endif