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

#include <stddef.h>

void* memset(void *str, int c, size_t n);
void *memcpy(const void *to, const void *from, size_t n);
char* memchr(register const char* src_void, int c, size_t length);
size_t strlen(const char *s);
int strcmp(const char *str1, const char *str2);
int strcasecmp (const char *s1, const char *s2);
int strncasecmp (const char *s1, const char *s2, size_t n);
char *strchr(const char *s, int c);
char *strrchr(const char *s, int c);
int islower(int c);
int isupper(int c);
int tolower(int c);
int toupper(int c);
size_t strnlen(const char* str, size_t maxlen);
int strncmp(const char* s1, const char* s2, size_t n);
char *strncpy(char *to, const char *from, size_t n);
char *strcpy(char *to, const char *from);
char *
strncat (char *__restrict s1,
	const char *__restrict s2,
	size_t n);

char *
strcat (char *__restrict s1,
	const char *__restrict s2);


#endif

