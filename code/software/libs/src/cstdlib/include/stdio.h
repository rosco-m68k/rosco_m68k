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
#define stdin   (FILE*)0

char *fgets(char *buf, int len, FILE *ignored);

#endif

