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

void* memset(void *str, int c, size_t n) {
    // totally naive implementation, will do for now...
    uint8_t *buf = (uint8_t*) str;

    for (uint8_t *end = buf + n; buf < end; *buf++ = c)
        ;

    return str;
}

void* memcpy(const void *to, const void *from, size_t n) {
    // totally naive implementation, will do for now...
    uint8_t *fbuf = (uint8_t*) from;
    uint8_t *tbuf = (uint8_t*) to;

    for (uint8_t *end = fbuf + n; fbuf < end; *tbuf++ = *fbuf++)
        ;

    return tbuf;
}

char* memchr(register const char* src_void, int c, size_t length) {
  const unsigned char *src = (const unsigned char *)src_void;

  while (length-- > 0) {
      if (*src == c) {
          return (char*)src;
      }
      src++;
  }
  return NULL;
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

int isupper(int c) {
  return (c >= 'A' && c <= 'Z');
}

int islower(int c) {
  return (c >= 'a' && c <= 'z');
}

int toupper(int c) {
  return islower(c) ? (c) - ('a' - 'A') : c;
}

int tolower(int c) {
  return isupper(c) ? (c) + ('a' - 'A') : c;
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

int strncasecmp (const char *s1, const char *s2, size_t n) {
    const unsigned char *p1 = (const unsigned char *) s1;
    const unsigned char *p2 = (const unsigned char *) s2;
    int result = 0;

    if (p1 == p2) {
        return 0;
    }

    while (n-- && (result = tolower (*p1) - tolower (*p2++)) == 0) {
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

size_t strnlen(const char* str, size_t maxlen) {
    char*  p = memchr(str, 0, maxlen);
    if (p == NULL) {
        return maxlen;
    } else {
        return (p - str);
    }
}

int strncmp(const char* s1, const char* s2, size_t n) {
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

char* strncpy(char *to, const char *from, size_t n) {
  size_t size = strnlen (from, n);
  if (size != n) {
    memset (to + size, '\0', n - size);
  }

  return memcpy (to, from, size);
}

char *strcpy(char *to, const char *from) {
	register char *d = to;

    while ((*d++ = *from++) != 0)
		;

	return to;
}

/*
FUNCTION
	<<strncat>>---concatenate strings

INDEX
	strncat

SYNOPSIS
	#include <string.h>
	char *strncat(char *restrict <[dst]>, const char *restrict <[src]>,
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