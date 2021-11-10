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
 * Declare stdlib routines when compiling for freestanding envs.
 * No implementations are provided....
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_ZEMBEDDED_H
#define __ROSCO_M68K_ZEMBEDDED_H
#ifdef ZEMBEDDED

#include <stddef.h>

void    *memset (void *mem, int val, size_t len);
int     strcmp  (const char *s1, const char *s2);
int     strlen  (const char *str);

#endif
#endif /* __ROSCO_M68K_ZEMBEDDED_H */
