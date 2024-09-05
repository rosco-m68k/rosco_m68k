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
 * Controller for concept boot screen
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <stdbool.h>

#include "model.h"
#include "backend.h"

#include "config.h"

#ifdef ENABLE_ANIM
static void tick_anims(Model *model, uint32_t now) {
    Animation* current_front = (Animation*)model->animations_front.next;
    Animation* current_back = (Animation*)model->animations_back.next;

    if (current_front || current_back) {
        if (model->last_4t_timer_ticks == 0) {
            // first run, just set it up...
            // (or we've hit a rare actual zero rollover, whatever...)
            model->last_4t_timer_ticks = now;
        } else {
            uint32_t elapsed = now - model->last_4t_timer_ticks;

            // 4tick interval timer
            if (elapsed >= 4) {

                while (current_front || current_back) {
                    if (current_front) {
                        if (!current_front->tick(now, current_front)) {
                            list_delete(&current_front->node);
                            model->anim_list_dirty = true;
                        }
                        current_front = (Animation*)current_front->node.next;
                    }
                    if (current_back) {
                        if (!current_back->tick(now, current_back)) {
                            list_delete(&current_back->node);
                            model->anim_list_dirty = true;
                        }
                        current_back = (Animation*)current_back->node.next;
                    }
                }

                model->last_4t_timer_ticks = backend_get_ticks();
            }
        }
    }
}
#else
#define tick_anims(...)
#endif

static bool update_timers(__attribute__((unused)) Model *model) {
#if defined(ENABLE_ANIM) || defined(ENABLE_TIMER)
    uint32_t now = backend_get_ticks();
#endif

    // Do animations first, unless there aren't any active...
    tick_anims(model, now);

#ifdef ENABLE_TIMER
    // Do 1s countdown timer, unless it's already expired
    if (model->timer_secs_left) {
        if (model->last_1s_timer_ticks == 0) {
            // first run, just set it up...
            // (or we've hit a rare actual zero rollover, whatever...)
            model->last_1s_timer_ticks = now;
        } else {
            uint32_t elapsed = now - model->last_1s_timer_ticks;

            // 1sec interval timer
            if (elapsed >= 100) {
                model->last_1s_timer_ticks = backend_get_ticks();
                model->timer_secs_left--;
            }

            if (!model->timer_secs_left) {
                // expired - return true.
                return true;
            }
        }
    }
#endif

    return false;
}

bool control(Model *model) {
    // do first, so keypress can set zero and kill timer...
    if (update_timers(model)) {
#       ifdef DEBUG_MODEL        
        printf("Timer expired; default choice: %d\n", model->selection);
#       endif
        return false;
    };

    BACKEND_EVENT event = backend_poll_event();
    switch (event) {
    case UP:
        model->timer_secs_left = 0;

        if (model->selection == 0) {
            model->selection = model->n_items - 1;
        } else {
            model->selection--;
        }

        return true;
    case DOWN:
        model->timer_secs_left = 0;

        if (model->selection == model->n_items - 1) {
            model->selection = 0;
        } else {
            model->selection++;
        }

        return true;
#ifndef __ROSCO_M68K_ROM__
    case QUIT:
        return false;
#endif
    default:
        return true;
    }
}
