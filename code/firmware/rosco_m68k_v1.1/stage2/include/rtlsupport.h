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
 * Prototypes for C RTL functions we have implementations for
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_RTLSUPPORT_H
#define _ROSCOM68K_RTLSUPPORT_H

typedef   uint32_t    size_t;

void* memset(void *str, int c, long unsigned int n);
void *memcpy(const void *from, const void *to, long unsigned int n);
int strcmp(const char *str1, const char *str2);

#endif

