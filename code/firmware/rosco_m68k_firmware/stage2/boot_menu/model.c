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
 * Model for concept boot screen
 * ------------------------------------------------------------
 */
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include "model.h"

#ifdef ENABLE_ANIM
static bool anims_dirty(Animation *current_anim) {
    while (current_anim) {
        if (current_anim->dirty) {
            return true;
        }
        current_anim = (Animation*)current_anim->node.next;
    }

    return false;
}
#endif

bool model_is_dirty(Model *current, Model *target) {
    if (!current || !target) {
        return current != target;
    } else if (current == target) {
        return false;
    } else {
        bool dirty = current->selection != target->selection 
            || current->timer_secs_left != target->timer_secs_left
            || current->n_items != target->n_items 
            || current->items != target->items          // N.B. Not deep equality!

#           ifdef ENABLE_ANIM
            || target->anim_list_dirty
            || anims_dirty((Animation*)target->animations_back.next)
            || anims_dirty((Animation*)target->animations_front.next)
#           endif
            ;

#       ifdef ENABLE_ANIM
        // TODO HACK - We need to set this (it only lasts one frame) but NOT HERE!!
        target->anim_list_dirty = false;
#       endif

        memcpy(current, target, sizeof(Model));

        return dirty;
    }
}