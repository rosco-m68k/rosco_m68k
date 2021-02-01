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
 * Simple, incomplete "stdio" for simple programs that need it
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_STDIO_H
#define _ROSCOM68K_STDIO_H

#include <stdarg.h>
#include "printf.h"

typedef void    FILE;

// TODO these aren't correct but the stdlib currently ignores them
// anyway, they are only here to allow code to compile without changes.
#define stdin   ((FILE*)0)
#define stdout  ((FILE*)1)

char *fgets(char *buf, int len, FILE *ignored);

#endif

