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

extern void mcPrint(char *str);

static char buf[2];
static char crbuf[2] = { '\r', 0 };

/*
 * This is used by printf.
 */
void _putchar(char chr) {
  if (chr == '\n') {
    // is LF, print CR too
    mcPrint(crbuf);
  }

  buf[0] = chr;
  mcPrint(buf);
}

