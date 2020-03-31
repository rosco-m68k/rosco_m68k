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
 * Stupid 'fgets' replacement that ignores the stream
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <basicio.h>

char* fgets(char *buf, int n, FILE *stream) {
  int len = readline(buf, n);

  if (len > 0 && len < (n - 1)) {
    buf[len] = '\n';
    buf[len+1] = 0;
  }

  return buf;
}

