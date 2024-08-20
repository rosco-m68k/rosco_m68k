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
 * Header for callers of the menu
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_BOOT_MENU_H
#define __ROSCO_BOOT_MENU_H

int do_boot_menu(char **menu_items, int n_menu_items);

#endif