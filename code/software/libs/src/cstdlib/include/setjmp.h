/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2023 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * setjmp/longjmp
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_SETJMP_H
#define _ROSCOM68K_SETJMP_H

#include <stdint.h>

typedef uint32_t jmp_buf[14];

void longjmp (jmp_buf jmpb, int retval);
int  setjmp (jmp_buf jmpb);

#endif// _ROSCOM68K_SETJMP_H

