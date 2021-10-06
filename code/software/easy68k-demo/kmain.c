/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * rosco_m68k "kernel main" for baremetal programs
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <basicio.h>
#include <machine.h>

#ifdef PERFORM_LINKAGE_CHECK
#include "linkcheck.h"
#endif

extern void easy68k_example();

void kmain() {

  print("\033[H\033[2J"); // home & clear screen (VT100)

#ifdef PERFORM_LINKAGE_CHECK
  checkLinkage();
#endif

  print("\033[H\033[2J"); // home & clear screen (VT100)

  easy68k_example();
}
