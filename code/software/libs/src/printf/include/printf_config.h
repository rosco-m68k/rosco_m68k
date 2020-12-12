/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2019 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Kernel-specific printf configuration (see 3rdparty/printf.c)
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_PRINTF_CONFIG_H
#define _ROSCOM68K_PRINTF_CONFIG_H

#define PRINTF_DISABLE_SUPPORT_EXPONENTIAL
#define PRINTF_DISABLE_SUPPORT_LONG_LONG
#define PRINTF_DISABLE_SUPPORT_PTRDIFF_T

extern void (*putchar_func)(char chr, void* arg);

#endif
