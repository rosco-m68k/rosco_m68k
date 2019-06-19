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
 * This is the entry point for the Kernel.
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdnoreturn.h>
#include <stdbool.h>

#include "machine.h"
#include "system.h"

static uint8_t * const mfp_gpdr = (uint8_t * const)0xf80001;

noreturn void kmain() {
  int i = 0;

  do {
    for (int j = 0; j < 100000; j++) {
      i = j;
    }

    i = 2;

    *(mfp_gpdr) ^= i;
  } while (true);

  HALT();
}
