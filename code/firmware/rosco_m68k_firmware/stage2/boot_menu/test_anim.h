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

#ifndef __TEST_ANIM_H
#define __TEST_ANIM_H

#include <stdbool.h>
#include "animation.h"
#include "config.h"

#ifdef ENABLE_ANIM
typedef struct {
    Animation       animation;
    int             next_y;
} TestAnimation;

bool test_anim_tick(uint32_t ticks, Animation *anim);
void test_anim_paint(Animation *anim);
#endif

#endif