/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2019-2022 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Stub "ctype" for simple programs that need it
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_CTYPE_H
#define _ROSCOM68K_CTYPE_H

int isalnum(int ch);
int isalpha(int ch);
int islower(int ch);
int isupper(int ch);
int isdigit(int ch);
int isxdigit(int ch);
int iscntrl(int ch);
int isgraph(int ch);
int isspace(int ch);
int isblank(int ch);
int isprint(int ch);
int ispunct(int ch);

int tolower(int ch);
int toupper(int ch);

#endif

