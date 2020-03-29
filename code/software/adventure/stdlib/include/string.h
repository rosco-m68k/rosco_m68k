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
 * Simple, incomplete "string.h" for simple programs that need it
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_STRING_H
#define _ROSCOM68K_STRING_H

void* memset(void *str, int c, long unsigned int n);
void *memcpy(const void *from, const void *to, long unsigned int n);
size_t strlen(const char *s);
int strcmp(const char *str1, const char *str2);
int strcasecmp (const char *s1, const char *s2);
char *strchr(const char *s, int c);
char *strrchr(const char *s, int c);
int isupper(char c);
int tolower(char c);

#endif

