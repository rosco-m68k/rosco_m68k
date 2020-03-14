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
#include "stdlib.h"
#include "linkcheck.h"

static volatile uint8_t * const mfp_gpdr = (uint8_t * const)MFP_GPDR;

noreturn void kmain() {
  print("\033[2J");
  println("Hello, World from the \"kernel\"!");

  checkLinkage();

  while (true) {
    *(mfp_gpdr) ^= 2;

    delay(125000);
  }
}

