/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Xosera console low-level primitives
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_XOSERA_CON_H
#define __ROSCO_M68K_XOSERA_CON_H

#include <stdbool.h>

/**
 * Returns true if a Xosera is installed, false otherwise.
 */
bool HAVE_XOSERA();

/**
 * Initialize the Xosera console.
 */
bool XOSERA_CON_INIT();

/**
 * Install handlers for syscall PRINT/PRINTLN
 */
void XOSERA_CON_INSTALLHANDLERS();

#endif  //  __ROSCO_M68K_XOSERA_CON_H

