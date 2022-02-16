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
 * Basic implementations for string routines, until we get 
 * a libc sorted...
 * ------------------------------------------------------------
 */

#include <strings.h>
#include <ctype.h>
#include <stddef.h>
#include <string.h>

int strcasecmp(const char *s1, const char *s2) {
    const unsigned char *p1 = (const unsigned char *) s1;
    const unsigned char *p2 = (const unsigned char *) s2;
    int result;

    if (p1 == p2) {
        return 0;
    }

    while ((result = tolower(*p1) - tolower(*p2++)) == 0) {
        if (*p1++ == '\0') {
            break;
        }
    }

    return result;
}

int strncasecmp(const char *s1, const char *s2, size_t n) {
    const unsigned char *p1 = (const unsigned char *) s1;
    const unsigned char *p2 = (const unsigned char *) s2;
    int result = 0;

    if (p1 == p2) {
        return 0;
    }

    while (n-- && (result = tolower(*p1) - tolower(*p2++)) == 0) {
        if (*p1++ == '\0') {
            break;
        }
    }

    return result;
}
