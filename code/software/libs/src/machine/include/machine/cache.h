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
 * C prototypes for machine cache control routines in assembler
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_MACHINE_CACHE_H
#define _ROSCOM68K_MACHINE_CACHE_H

#include <stdint.h>

void mcEnableCaches(void);
void mcDisableCaches(void);

uint32_t mcStoreCaches(void);
void mcRestoreCaches(uint32_t cacr);

#endif//_ROSCOM68K_MACHINE_CACHE_H
