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
 * GDB support
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_GDB_H
#define _ROSCOM68K_GDB_H

/**
 * Start debugging. Installs the debugging infrastructure into
 * your process and takes over UART B for debugging purposes.
 * 
 * You'll probably want to execute a `breakpoint` immediately
 * after this to pause the system until your debugger connects.
 * 
 * @return true if debugging can be supported on your system
 * @return false if debugging cannot be supported on your system
 */
bool start_debugger(void);

/**
 * Clean-up the debugging infrastructure, and put traps and 
 * IRQs back the way they were.
 * 
 * You don't _have_ to call this, but your system might not
 * function properly until you hard reset if you don't.
 */
void cleanup_debugger(void);

/**
 * Execute a software breakpoint, and trap to the debugger.
 * 
 * If the debugger is not yet connected, this will pause until it
 * is, which allows you to wait for connection. 
 */
void breakpoint(void);

#endif//_ROSCOM68K_GDB_H


