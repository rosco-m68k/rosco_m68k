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
 * Animation support for concept boot screen
 * ------------------------------------------------------------
 */

#ifndef __ANIMATION_H
#define __ANIMATION_H

#include <stdint.h>

#include "config.h"

#ifdef ENABLE_ANIM
#include "list.h"

typedef struct Anim {
    ListNode node;
    bool (*tick)(uint32_t ticks, struct Anim *anim);
    void (*paint)(struct Anim *anim);
    bool dirty;
} Animation;
#endif

#endif