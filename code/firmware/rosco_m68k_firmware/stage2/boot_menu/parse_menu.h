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
 * Menu configuration parser
 * ------------------------------------------------------------
 */

#ifndef __PARSE_MENU_H
#define __PARSE_MENU_H

#include <stdbool.h>

#define MAX_TEXT_LENGTH 40
#define MAX_DATA_LENGTH 60

typedef enum {
    MENU_ITEM_EXIT      = 0,
    MENU_ITEM_ROMFS,
} MENU_ITEM_TYPE;

typedef struct {
    char                text[MAX_TEXT_LENGTH + 1];
    char                data[MAX_DATA_LENGTH + 1];
    MENU_ITEM_TYPE      type;
} MenuItem;

bool parse_menu(const char *input, size_t input_length, int max_items, MenuItem *items, int *n_items);

#endif