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
 * Stub "stdlib" for simple programs that need it
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_STDLIB_H
#define _ROSCOM68K_STDLIB_H

#ifndef NULL
#define NULL ((void*) 0)
#endif

#include <stddef.h>

void exit(int status);
void abort(void);
void *malloc(size_t size);
void free(void *ptr);
void *realloc(void *ptr, size_t size);
void *calloc(size_t nitems, size_t size);

#endif

