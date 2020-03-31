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
 * Basic implementations for string routines, until we get 
 * a libc sorted...
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stddef.h>

void* memset(void *str, int c, long unsigned int n) {
    // totally naive implementation, will do for now...
    uint8_t *buf = (uint8_t*) str;

    for (uint8_t *end = buf + n; buf < end; *buf++ = c)
        ;

    return str;
}

void* memcpy(const void *from, const void *to, long unsigned int n) {
    // totally naive implementation, will do for now...
    uint8_t *fbuf = (uint8_t*) from;
    uint8_t *tbuf = (uint8_t*) to;

    for (uint8_t *end = fbuf + n; fbuf < end; *tbuf++ = *fbuf++)
        ;

    return tbuf;
}

size_t strlen(const char *s) {
    size_t i;
    for (i = 0; s[i] != '\0'; i++) ;
    return i;
}

int strcmp(const char *str1, const char *str2) {
    // totally naive implementation, will do for now...
    register char c1, c2;

    while ((c1 = *str1++)) {
        if (!(c2 = *str2++)) {
            return 1;
        } else if (c1 != c2) {
            return c1 - c2;
        }
    }

    if (*str2) {
        return -1;
    } else {
        return 0;
    }
}

int isupper(char c) {
  return (c > 'A' && c < 'Z');
}

int tolower(char c) {
  return isupper(c) ? (c) - 'A' + 'a' : c;
}

int strcasecmp (const char *s1, const char *s2) {
    const unsigned char *p1 = (const unsigned char *) s1;
    const unsigned char *p2 = (const unsigned char *) s2;
    int result;

    if (p1 == p2) {
        return 0;
    }

    while ((result = tolower (*p1) - tolower (*p2++)) == 0) {
        if (*p1++ == '\0') {
            break;
        }
    }

    return result;
}

char *strchr(const char *s, int c) {
    while (*s != (char)c) {
        if (!*s++) {
            return 0;
        }
    }
    return (char *)s;
}

char *strrchr(const char *s, int c) {
    const char* ret=0;
    do {
        if( *s == (char)c ) {
            ret=s;
        }
    } while(*s++);
    return (char*)ret;
}

