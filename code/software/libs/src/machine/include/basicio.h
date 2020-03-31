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
 * Some basic IO routines for rosco_m68k.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_BASICIO_H
#define _ROSCOM68K_BASICIO_H

#include <stdint.h>
#include <machine.h>

#define sendchar mcSendchar
#define readchar mcReadchar

#define print mcPrint
#define println mcPrintln

#define delay mcBusywait

void printuint(uint32_t num);
void printuchar(uint8_t num);
void printushort(uint16_t num);

int readline(char *buf, int buf_len);

#endif

