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
 * Configures printf. Don't call this until the serial driver
 * is loaded and initialized.
 * ------------------------------------------------------------
 */
#include "servers/serial.h"

static Serial *serial;

/*
 * This is used by printf.
 */
void _putchar(char chr) {
  serial->SendChar(chr);
}

void __initializePrintf(Serial *theSerial) {
  serial = theSerial;
}

