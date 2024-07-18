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
 * Main for concept boot screen
 * ------------------------------------------------------------
 */

#include <stdio.h>

#include "model.h"
#include "view.h"
#include "controller.h"

#ifdef ENABLE_ANIM
#include "animation.h"
#ifdef SHOW_TEST_ANIM
#include "test_anim.h"
#endif
#endif

#include "backend.h"

#ifndef ROSCO_M68K
static int demo_n_menu_items = 4;
static char* demo_menu_items[] = {
    "Program loader",
    "MicroPython",
    "System configuration",
    "Memory check & diagnostic",
};
#endif

static Model model;
static View view;

#ifdef ENABLE_ANIM
#ifdef SHOW_TEST_ANIM
static TestAnimation test_animation;
static TestAnimation test_animation_2;
#endif
#endif

int do_boot_menu(char **menu_items, int n_menu_items) {
    if (!backend_init()) {
        return -2;
    }

    model.n_items = n_menu_items;
    model.items = menu_items;
    model.mem_count = backend_get_memsize();
    model.cpu = backend_get_cpu();
    model.mhz = backend_get_cpu_mhz();
    model.timer_secs_left = 5;

#ifdef ENABLE_ANIM
#ifdef SHOW_TEST_ANIM
    test_animation.animation.tick = test_anim_tick;
    test_animation.animation.paint = test_anim_paint;
    test_animation_2.animation.tick = test_anim_tick;
    test_animation_2.animation.paint = test_anim_paint;
    test_animation_2.next_y = 40;

    list_insert_after((ListNode*)&test_animation, &model.animations_front);
    list_insert_after((ListNode*)&test_animation_2, &model.animations_back);
#endif
#endif

    view_init(&view, &model);

    while (control(&model)) {
        view_repaint(&view, false);
    }

    backend_done();

    return model.selection;
}

#ifndef ROSCO_M68K
int main(void) {
    do_boot_menu(demo_menu_items, demo_n_menu_items);
    return 0;
}
#endif
