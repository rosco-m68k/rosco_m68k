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
#include "machine.h"

static volatile uint8_t * const mfp_gpdr = (uint8_t * const)MFP_GPDR;

noreturn void kmain() {
  mcPrintln("Hello, World from the \"kernel\"!");

  while (true) {
    *(mfp_gpdr) ^= 2;

    mcBusyWait(125000);
  }
}


