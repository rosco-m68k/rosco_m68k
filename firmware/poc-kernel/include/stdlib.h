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
 * Some basic 'stdlib'-type routines.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_STDLIB_H
#define _ROSCOM68K_STDLIB_H

#include <stdint.h>

void print(char *str);
void println(char *str);

void printuint(uint32_t num);
void printushort(uint16_t num);
void printuchar(uint8_t num);

void delay(uint32_t ticks);

#endif

