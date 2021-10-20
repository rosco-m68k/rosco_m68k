/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Stage-2-specific 'machine.h'
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_S2MACHINE_H
#define _ROSCOM68K_S2MACHINE_H

void mcPrint(char*);
void mcHalt();
void mcBusywait(uint32_t nops);

#endif//_ROSCOM68K_S2MACHINE_H

