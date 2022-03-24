/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v1
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * V9958 console low-level primitives
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_V9958_CON_H
#define __ROSCO_M68K_V9958_CON_H

#include <stdbool.h>

/**
 * Returns true if a V9958 is installed, false otherwise.
 */
bool HAVE_V9958();

/**
 * Initialize the V9958 console.
 */
void V9958_CON_INIT();

/**
 * Install handlers for syscall PRINT/PRINTLN
 */
void V9958_CON_INSTALLHANDLERS();

#endif  //  __ROSCO_M68K_V9958_CON_H
