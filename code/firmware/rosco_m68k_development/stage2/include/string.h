/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2019-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Simple, incomplete "string.h" for simple programs that need it
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_STRING_H
#define _ROSCOM68K_STRING_H

#include <stddef.h>

void* memset(void *str, int c, long unsigned int n);
void *memcpy(const void *to, const void *from, long unsigned int n);
char* memchr(register const char* src_void, int c, size_t length);
size_t strlen(const char *s);
int strcmp(const char *str1, const char *str2);
int strcasecmp (const char *s1, const char *s2);
char *strchr(const char *s, int c);
char *strrchr(const char *s, int c);
int isupper(char c);
int tolower(char c);
size_t strnlen(const char* str, size_t maxlen);
int strncmp(const char* s1, const char* s2, size_t n);
char *strncpy(char *s1, const char *s2, size_t n);

#endif

