/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|         libraries
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
#include <stdnoreturn.h>

typedef uint16_t    jmp_buf[27];

noreturn void longjmp(jmp_buf jmpb, int retval);

int  setjmp(jmp_buf jmpb);

#endif// _ROSCOM68K_SETJMP_H

