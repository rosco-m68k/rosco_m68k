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
 * Super-basic "stdint.h" just the main types for programs that need them
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_STDINT_H
#define _ROSCOM68K_STDINT_H

#include <stddef.h>

typedef signed char			int8_t;
typedef short				int16_t;
typedef long				int32_t;
typedef long long			int64_t;
typedef unsigned char		uint8_t;
typedef	unsigned short		uint16_t;
typedef long unsigned int	uint32_t;
typedef unsigned long long	uint64_t;
typedef int					intptr_t;
typedef unsigned int		uintptr_t;
typedef long long			intmax_t;
typedef unsigned long long	uintmax_t;

#endif /* _ROSCOM68K_STDINT_H */
