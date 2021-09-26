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

/* char ready on default UART */
#define checkchar mcCheckchar
/* read char from default UART */
#define readchar mcReadchar
/* send char to default UART */
#define sendchar mcSendchar
/* send char to default console/UART */
#define printchar mcPrintchar
/* send string to default console/UART */
#define print mcPrint
/* send string to default console/UART with newline */
#define println mcPrintln
/* busy wait delay (500 ~= 1ms @ 10MHz 68K) */
#define delay mcBusywait

void printuint(uint32_t num);
void printuchar(uint8_t num);
void printushort(uint16_t num);

int readline(char *buf, int buf_len);

#endif

