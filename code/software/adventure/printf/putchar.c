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
 * Configures printf. 
 * ------------------------------------------------------------
 */
#include "easy68k/easy68k.h"

/*
 * This is used by printf.
 */
void _putchar(char chr) {
  if (chr == '\n') {
    // is LF, print CR too
    e68PrintLen("\r", 1);
  }

  e68PrintLen(&chr, 1);
}

