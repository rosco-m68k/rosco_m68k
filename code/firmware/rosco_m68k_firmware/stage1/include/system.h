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
 * Typedefs and utilities for system-level structures.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_SYSTEM_H
#define _ROSCOM68K_SYSTEM_H

#include <stdint.h>

// This is the address kernels should be loaded at
#define KERNEL_LOAD_ADDRESS   0x40000

/*
 * The SystemDataBlock is a global reserved structure at $400-$500 (256 bytes).
 */
typedef struct {
  uint32_t      magic;                /* Magic number B105DA7A */
  uint32_t      oshi_code;            /* OSHI code, only valid in OSHI condition */
  uint16_t      heartbeat_counter;    /* Counter used to flash I0 */
  uint16_t      heartbeat_frequency;  /* Value used to reset heartbeat counter (100 = ~1 beat per second) */
  uint32_t      upticks;              /* Running counter of the number of ticks the system has been up */
  uint32_t      e68k_reserved;        /* Reserved for Easy68k */
  uint32_t      memsize;              /* Size of first contiguous block of RAM */
  uint32_t      uartbase;             /* Base address of default UART */
  uint32_t      cpu_model:3;          /* CPU type */
  uint32_t      cpu_speed:29;         /* CPU speed */
} __attribute__ ((packed)) SystemDataBlock;

#endif

