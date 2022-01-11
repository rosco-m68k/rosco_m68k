/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2010-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * C prototypes for serial routines implemented in assembly.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_SERIAL_H
#define _ROSCOM68K_SERIAL_H

#include <stdint.h>

void DISABLE_RECV();
void ENABLE_RECV();

void DISABLE_XMIT();
void ENABLE_XMIT();

uint8_t RECVCHAR();
void SENDCHAR(uint8_t);


#endif

