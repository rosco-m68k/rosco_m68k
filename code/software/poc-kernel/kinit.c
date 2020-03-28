/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Pre-main initialization for POC kernel.
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include "machine.h"

// Linker defines
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end;

void kinit() {
  // zero .bss
  for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst++ = 0);
}

