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
 * Simple, incomplete "string.h" for simple programs that need it
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_STRING_H
#define _ROSCOM68K_STRING_H

#include <stddef.h>

void *memchr(const void *s, int c, size_t n);
void *memcpy(void *__restrict s1, const void *__restrict s2, size_t n);
void *memset(void *s, int c, size_t n);
char *strcat(char *__restrict s1, const char *__restrict s2);
char *strchr(const char *s, int c);
int strcmp(const char *s1, const char *s2);
char *strcpy(char *__restrict s1, const char *__restrict s2);
size_t strlen(const char *s);
char *strncat(char *__restrict s1, const char *__restrict s2, size_t n);
int strncmp(const char *s1, const char *s2, size_t n);
char *strncpy(char *__restrict s1, const char *__restrict s2, size_t n);
size_t strnlen(const char *s, size_t maxlen);
char *strrchr(const char *s, int c);

#endif
