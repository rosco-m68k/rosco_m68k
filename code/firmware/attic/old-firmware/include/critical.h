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
 * Critical sections.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_CRITICAL_H
#define _ROSCOM68K_CRITICAL_H

#include <stdnoreturn.h>

/**
 * Enter a critical section (disables all maskable interrupts).
 */
void CRITICAL_BEGIN();

/**
 * End a critical section (Re-enables interrupts)
 */
void CRITICAL_END();

#endif

