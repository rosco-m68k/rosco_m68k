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
 * Typedefs and utilities for system-level structures.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_SYSTEM_H
#define _ROSCOM68K_SYSTEM_H

#include <stdint.h>

/*
 * The MemoryRegion structure describes a region of memory,
 * allocated or unallocated (depending on which list it appears in).
 */
typedef struct _MemoryRegion {
  void                  *start;
  uint32_t              size;
  uint32_t              flags;
  struct _MemoryRegion  *next;
} __attribute__ ((packed)) MemoryRegion;

/*
 * The Registers structure is the format in which the MC68010 pushes
 * registers onto the stack.
 */
typedef struct {
  uint32_t      sr;
  uint32_t      pc;
} __attribute__ ((packed)) Registers;

/*
 * The Task structure describes a task in the system.
 */
typedef struct _Task {
  uint32_t      tid;
  uint16_t      flags;
  uint8_t       priority;
  uint8_t       status;
  Registers     *regs;
  MemoryRegion  *region_list;
  struct _Task  *next;
  uint32_t      reserved[2];
} __attribute__ ((packed)) Task;

/*
 * The SystemDataBlock is a global reserved structure at $400-$500 (256 bytes).
 */
typedef struct {
  uint32_t      magic;                /* Magic number B105DA7A */
  uint32_t      oshi_code;            /* OSHI code, only valid in OSHI condition */
  uint16_t      heartbeat_counter;    /* Counter used to flash I0 */
  uint16_t      heartbeat_frequency;  /* Value used to reset heartbeat counter (100 = ~1 beat per second) */
  uint32_t      upticks;              /* Running counter of the number of ticks the system has been up */
  MemoryRegion  *free_list;           /* List of free memory blocks */
  Task          *next_runnable_task;  /* Next runnable task (circular list, doubly linked) */
  Task          *suspended_tasks;     /* Tasks waiting on some condition */
  Task          *current_task;        /* Currently-running task */
  uint32_t      reserved[56];         /* Reserved */

} __attribute__ ((packed)) SystemDataBlock;

#endif

