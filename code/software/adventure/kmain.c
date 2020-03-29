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
#include <easy68k/easy68k.h>

extern void main(void);

void kmain() {
  // Disable standard input prompt, adventure provides its own!
  e68SetDisplayOpt(E68K_DISPLAY_PROMPT_OFF);

  // Run adventure!
  main();

  // Warm-reboot machine when quit
  __asm__ __volatile__ (
      "moveal 0xfc0004.l, %a0\n\t"
      "jmp %a0@\n\t"
  );
}

