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

#include <string.h>
#include <stdint.h>
#include <stddef.h>

void *memchr(const void *s, int c, size_t n) {
  const unsigned char *src = (const unsigned char *)s;

  while (n-- > 0) {
      if (*src == c) {
          return (char*)src;
      }
      src++;
  }
  return NULL;
}

void *memcpy(void *__restrict s1, const void *__restrict s2, size_t n) {
    // totally naive implementation, will do for now...
    uint8_t *fbuf = (uint8_t*) s2;
    uint8_t *tbuf = (uint8_t*) s1;

    for (uint8_t *end = fbuf + n; fbuf < end; *tbuf++ = *fbuf++)
        ;

    return tbuf;
}

void *memset(void *s, int c, size_t n) {
    // totally naive implementation, will do for now...
    uint8_t *buf = (uint8_t*) s;

    for (uint8_t *end = buf + n; buf < end; *buf++ = c)
        ;

    return s;
}

char *strchr(const char *s, int c) {
    while (*s != (char)c) {
        if (!*s++) {
            return NULL;
        }
    }
    return (char *)s;
}

int strcmp(const char *s1, const char *s2) {
    // totally naive implementation, will do for now...
    register char c1, c2;

    while ((c1 = *s1++)) {
        if (!(c2 = *s2++)) {
            return 1;
        } else if (c1 != c2) {
            return c1 - c2;
        }
    }

    if (*s2) {
        return -1;
    } else {
        return 0;
    }
}

char *strcpy(char *__restrict s1, const char *__restrict s2) {
	register char *d = s1;

    while ((*d++ = *s2++) != 0)
		;

	return s1;
}

size_t strlen(const char *s) {
    size_t i;
    for (i = 0; s[i] != '\0'; i++) ;
    return i;
}

int strncmp(const char *s1, const char *s2, size_t n) {
    const unsigned char *p1 = (const unsigned char *) s1;
    const unsigned char *p2 = (const unsigned char *) s2;
    int result = 0;

    if (p1 == p2) {
        return 0;
    }

    while(n-- && (result = *p1 - *p2++) == 0) {
        if (*p1++ == '\0')
            break;
    }

    return result;
}

char *strncpy(char *__restrict s1, const char *__restrict s2, size_t n) {
  size_t size = strnlen (s2, n);
  if (size != n) {
    memset (s1 + size, '\0', n - size);
  }

  return memcpy (s1, s2, size);
}

size_t strnlen(const char *s, size_t maxlen) {
    char *p = memchr(s, 0, maxlen);
    if (p == NULL) {
        return maxlen;
    } else {
        return (p - s);
    }
}

char *strrchr(const char *s, int c) {
    const char* ret = NULL;
    do {
        if(*s == (char)c) {
            ret = s;
        }
    } while(*s++);
    return (char*)ret;
}

/*
FUNCTION
	<<strncat>>---concatenate strings

INDEX
	strncat

SYNOPSIS
	#include <string.h>
	char *strncat(char *__restrict <[dst]>, const char *__restrict <[src]>,
                      size_t <[length]>);

DESCRIPTION
	<<strncat>> appends not more than <[length]> characters from
	the string pointed to by <[src]> (including the	terminating
	null character) to the end of the string pointed to by
	<[dst]>.  The initial character of <[src]> overwrites the null
	character at the end of <[dst]>.  A terminating null character
	is always appended to the result

WARNINGS
	Note that a null is always appended, so that if the copy is
	limited by the <[length]> argument, the number of characters
	appended to <[dst]> is <<n + 1>>.

RETURNS
	This function returns the initial value of <[dst]>

PORTABILITY
<<strncat>> is ANSI C.

<<strncat>> requires no supporting OS subroutines.

QUICKREF
	strncat ansi pure
*/

#include <string.h>
#include <limits.h>

/* Nonzero if X is aligned on a "long" boundary.  */
#define ALIGNED(X) \
  (((long)X & (sizeof (long) - 1)) == 0)

#if LONG_MAX == 2147483647L
#define DETECTNULL(X) (((X) - 0x01010101) & ~(X) & 0x80808080)
#else
#if LONG_MAX == 9223372036854775807L
/* Nonzero if X (a long int) contains a NULL byte. */
#define DETECTNULL(X) (((X) - 0x0101010101010101) & ~(X) & 0x8080808080808080)
#else
#error long int is not a 32bit or 64bit type.
#endif
#endif

#ifndef DETECTNULL
#error long int is not a 32bit or 64bit byte
#endif

char *
strncat (char *__restrict s1,
	const char *__restrict s2,
	size_t n)
{
  char *s = s1;

  while (*s1)
    s1++;
  while (n-- != 0 && (*s1++ = *s2++))
    {
      if (n == 0)
	*s1 = '\0';
    }

  return s;

}


char *
strcat (char *__restrict s1,
	const char *__restrict s2)
{

  char *s = s1;

  while (*s1)
    s1++;

  while ((*s1++ = *s2++))
    ;
  return s;
}
