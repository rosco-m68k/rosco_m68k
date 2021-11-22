#ifndef __CDEFS_H__
#define __CDEFS_H__

#include <stdint.h>

/*
  By default, the internal routines of kermit.c are not static,
  because this is not allowed in some embedded environments.
  To have them declared static, define STATIC=static on the cc
  command line.
*/
#ifdef XAC  /* HiTech's XAC cmd line is small */
#define STATIC static
#else /* XAC */
#ifndef STATIC
#define STATIC
#endif /* STATIC */
#endif	/* XAC */

/*
  By default we assume the compiler supports unsigned char and
  unsigned long.  If not you can override these definitions on
  the cc command line.
*/
#ifndef HAVE_UCHAR
typedef uint8_t UCHAR;
#endif /* HAVE_UCHARE */
#ifndef HAVE_ULONG
typedef uint32_t ULONG;
#endif /* HAVE_ULONG */
#ifndef HAVE_USHORT
typedef uint16_t USHORT;
#endif /* HAVE_USHORT */

#endif /* __CDEFS_H__ */
