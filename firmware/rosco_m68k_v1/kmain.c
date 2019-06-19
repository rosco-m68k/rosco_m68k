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

extern void __initializeKernelApiPtr();
extern void __initializeSerialServer();

noreturn void kmain() {
  // TODO Really ought to have zeroed BSS by this point...
  
  // Set up the rest of the System Data Block
  EARLY_PRINT_C("Initialising System Data Block...\r\n");
  // TODO
  
  // Set up the KernelAPI pointer (at 0x04)
  EARLY_PRINT_C("Initialising kernel API...\r\n");
  __initializeKernelApiPtr();

  // Have the serial server initalize itself
  // EARLY_PRINT_C("Initialising serial server...\r\n");
  //__initializeSerialServer();

  // Start the timer tick
  EARLY_PRINT_C("Software initialisation \x1b[1;32mcomplete\x1b[0m; Starting system tick...\r\n");
  START_HEART();
  
  // Blink IO1 forever to show we're still alive.
  int i = 0;

  do {
    for (int j = 0; j < 100000; j++) {
      i = j;
    }

    i = 2;

    *(mfp_gpdr) ^= i;
  } while (true);
}
