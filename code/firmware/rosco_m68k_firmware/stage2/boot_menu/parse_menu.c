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

#include <stdbool.h>
#include <string.h>
#include <stdio.h>

#include "parse_menu.h"

#define MAX_LINE_LENGTH     110         // extra space for 4 character data prefix + null
#define FIXED_PREFIX_LEN    4

bool parse_menu(const char *input, size_t input_length, int max_items, MenuItem *items, int *n_items) {
    char line[MAX_LINE_LENGTH];
    int item_count = 0;
    const char *start = input;
    const char *end = input + input_length;
    const char *line_end;

    if (input == NULL || input_length == 0 || max_items == 0 || items == NULL || n_items == NULL) {
        return false;
    }

    while (start < end && item_count < max_items) {
        // Find end of line
        line_end = memchr(start, '\n', end - start);
        if (!line_end) {
            line_end = end;
        }

        // Check line length
        size_t line_length = line_end - start;
        if (line_length > MAX_LINE_LENGTH) {
            // Skip this line if it's too long
            start = line_end + 1;
            continue;
        }

        // Copy line to buffer
        memcpy(line, start, line_length);
        line[line_length] = '\0';

        // Find colon in line
        char *colon = strchr(line, ':');
        if (!colon) {
            // Skip this line if it doesn't contain a colon
            start = line_end + 1;
            continue;
        }

        // Extract text and data
        size_t text_length = colon - line;
        const char *data_start = colon + 1;
        size_t data_length = line_length - text_length - 1;

        if (text_length == 0 || data_length == 0 || text_length > MAX_TEXT_LENGTH || data_length > (MAX_DATA_LENGTH + FIXED_PREFIX_LEN)) {
            // Skip this line if text or data is too short/long
            start = line_end + 1;
            continue;
        }

        // Copy text
        memcpy(items[item_count].text, line, text_length);
        items[item_count].text[text_length] = '\0';

        // Determine type and copy data
        if (strncmp(data_start, "exit", FIXED_PREFIX_LEN) == 0) {
            items[item_count].type = MENU_ITEM_EXIT;
            items[item_count].data[0] = '\0';
            item_count++;
        } else if (strncmp(data_start, "rom/", FIXED_PREFIX_LEN) == 0) {
            items[item_count].type = MENU_ITEM_ROMFS;
            memcpy(items[item_count].data, data_start + FIXED_PREFIX_LEN, data_length - FIXED_PREFIX_LEN);
            items[item_count].data[data_length - FIXED_PREFIX_LEN] = '\0';
            item_count++;
        }
        // If it's neither "exit" nor "rom/", we simply skip this line

        // Move to next line
        start = line_end + 1;
    }

    *n_items = item_count;
    return item_count > 0;
}