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
 * Debugging for concept boot screen
 * ------------------------------------------------------------
 */

#ifndef __DEBUG_H
#define __DEBUG_H

#ifdef __ROSCO_M68K_ROM__
#define debugf(...)
#else
#ifdef MODEL_DEBUG
#define debugf(...)     printf(__VA_ARGS__)
#else
#define debugf(...)
#endif
#endif

#endif