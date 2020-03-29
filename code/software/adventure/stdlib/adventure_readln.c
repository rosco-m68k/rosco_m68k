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
 * Fake 'fgets' replacement for adventure
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_CTYPE_H
#define _ROSCOM68K_CTYPE_H

#include <easy68k/easy68k.h>

void __adventure_readln(char *buf) {
  // No overrun protection here, but Readln is limited to 80 chars...
  int len = e68ReadlnStr(buf);

  if (len > 0) {
    buf[len] = '\n';
    buf[len+1] = 0;
  }
}
#endif

