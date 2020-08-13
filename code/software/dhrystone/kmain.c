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
 * This is the entry point for dhrystone benchmark.
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <basicio.h>

extern void main(void);

static long *upticks = (long*)0x40C;

long time() {
  return *upticks / 100;
}

void kmain() {
  printf("dhrystone benchmark\n");
#ifndef TIME
#ifndef TIMES
  // Run dhrystone benchmark!

  printf("Get your stopwatch ready...");
  delay(1000000);
#endif
#endif

  main();

  // Warm-reboot machine when quit
  __asm__ __volatile__ (
      "moveal 0xfc0004.l, %a0\n\t"
      "jmp %a0@\n\t"
  );
}

