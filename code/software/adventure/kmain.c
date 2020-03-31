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
 * This is the entry point for Jeff Tranter's Adventure.
 * ------------------------------------------------------------
 */

#include <stdio.h>

extern void main(void);

void kmain() {
  // Run adventure!
  main();

  // Warm-reboot machine when quit
  __asm__ __volatile__ (
      "moveal 0xfc0004.l, %a0\n\t"
      "jmp %a0@\n\t"
  );
}

