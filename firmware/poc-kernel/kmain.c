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
 * This is the entry point for the POC "kernel".
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdnoreturn.h>
#include <stdbool.h>

static volatile uint8_t * const mfp_gpdr = (uint8_t * const)0xf80001;

noreturn void kmain() {
  volatile int j; 

  while (true) {
    *(mfp_gpdr) ^= 2;

    for (int i = 0; i < 250000; i++) {
      j += 1;
    }
  }
}


